#!/usr/bin/env python3

from __future__ import annotations
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable
import argparse
import re
import struct
import sys
import zlib

LOAD_ADDRESS = 0x0401
HEADER_SIZE = 20
MAGIC = b"MTB1"

RAM_TOPS = (
    (0x2000, "8K"),
    (0x4000, "16K"),
    (0x8000, "32K"),
    (0xBC00, "48K"),
)

HEADER_STRUCT = struct.Struct("<4sBBHHHHHI")

KEYWORDS = (
    ("END", 0x80),
    ("FOR", 0x81),
    ("NEXT", 0x82),
    ("DATA", 0x83),
    ("INPUT", 0x84),
    ("DIM", 0x85),
    ("READ", 0x86),
    ("LET", 0x87),
    ("GOTO", 0x88),
    ("RUN", 0x89),
    ("IF", 0x8A),
    ("RESTORE", 0x8B),
    ("GOSUB", 0x8C),
    ("RETURN", 0x8D),
    ("REM", 0x8E),
    ("STOP", 0x8F),
    ("ON", 0x90),
    ("NULL", 0x91),
    ("WAIT", 0x92),
    ("LOAD", 0x93),
    ("SAVE", 0x94),
    ("DEF", 0x95),
    ("POKE", 0x96),
    ("PRINT", 0x97),
    ("CONT", 0x98),
    ("LIST", 0x99),
    ("CLEAR", 0x9A),
    ("GET", 0x9B),
    ("NEW", 0x9C),
    ("TAB(", 0x9D),
    ("TO", 0x9E),
    ("FN", 0x9F),
    ("SPC(", 0xA0),
    ("THEN", 0xA1),
    ("NOT", 0xA2),
    ("STEP", 0xA3),
    ("+", 0xA4),
    ("-", 0xA5),
    ("*", 0xA6),
    ("/", 0xA7),
    ("^", 0xA8),
    ("AND", 0xA9),
    ("OR", 0xAA),
    (">", 0xAB),
    ("=", 0xAC),
    ("<", 0xAD),
    ("SGN", 0xAE),
    ("INT", 0xAF),
    ("ABS", 0xB0),
    ("USR", 0xB1),
    ("FRE", 0xB2),
    ("POS", 0xB3),
    ("SQR", 0xB4),
    ("RND", 0xB5),
    ("LOG", 0xB6),
    ("EXP", 0xB7),
    ("COS", 0xB8),
    ("SIN", 0xB9),
    ("TAN", 0xBA),
    ("ATN", 0xBB),
    ("PEEK", 0xBC),
    ("LEN", 0xBD),
    ("STR$", 0xBE),
    ("VAL", 0xBF),
    ("ASC", 0xC0),
    ("CHR$", 0xC1),
    ("LEFT$", 0xC2),
    ("RIGHT$", 0xC3),
    ("MID$", 0xC4),
    ("GO", 0xC5),
)


class CompileError(ValueError):
    def __init__(self, source_name: str, line: int, column: int, message: str) -> None:
        self.source_name = source_name
        self.line = line
        self.column = column
        self.message = message
        super().__init__(f"{source_name}:{line}:{column}: error: {message}")


@dataclass(frozen=True)
class CompileWarning:
    source_name: str
    line: int
    column: int
    message: str
    def __str__(self) -> str:
        return (f"{self.source_name}:{self.line}:{self.column}: warning: {self.message}")


@dataclass(frozen=True)
class SourceLine:
    physical_line: int
    line_number: int
    statement_column: int
    statement: str
    tokenized: bytes


@dataclass(frozen=True)
class Compilation:
    source_name: str
    payload: bytes
    file_bytes: bytes
    line_count: int
    first_free: int
    ram_top: int
    ram_label: str
    crc32: int
    warnings: tuple[CompileWarning, ...]


def _ascii_error_position(data: bytes, offset: int) -> tuple[int, int]:
    prefix = data[:offset]
    line = 1
    column = 1
    index = 0

    while index < len(prefix):
        value = prefix[index]

        if value == 0x0D:
            line += 1
            column = 1

            if (index + 1 < len(prefix) and prefix[index + 1] == 0x0A):
                index += 1
        elif value == 0x0A:
            line += 1
            column = 1
        else:
            column += 1

        index += 1

    return line, column


def _warn_for_mixed_case_keyword(statement: str, position: int, source_name: str, physical_line: int, statement_column: int) -> tuple[CompileWarning, int] | None:
    remaining = statement[position:]

    for keyword, _token in KEYWORDS:
        candidate = remaining[: len(keyword)]

        if (any(character.isalpha() for character in keyword) and candidate.upper() == keyword and candidate != keyword):
            return (CompileWarning(source_name=source_name, line=physical_line, column=statement_column + position,
                    message=(f"'{candidate}' resembles keyword '{keyword}' but remains untokenized because MTB1 matching is case-sensitive")), len(keyword))

    return None


def tokenize_statement(statement: str, source_name: str, physical_line: int, statement_column: int) -> tuple[bytes, list[CompileWarning]]:
    output = bytearray()
    warnings: list[CompileWarning] = []

    position = 0
    quoted = False
    data_literal = False
    rem_literal = False
    warning_suppressed_until = 0
    
    while position < len(statement):
        character = statement[position]

        if rem_literal:
            output.extend(statement[position:].encode("ascii"))
            break

        if quoted:
            output.append(ord(character))
            position += 1

            if character == '"':
                quoted = False

            continue

        if character == '"':
            output.append(ord(character))
            position += 1
            quoted = True
            continue

        if data_literal:
            output.append(ord(character))
            position += 1

            if character == ":":
                data_literal = False

            continue

        if character == "?":
            output.append(0x97)
            position += 1
            continue

        # This reproduces the firmware's fast path for spaces, decimal text and punctuation from "0" through ";".
        if character == " " or ("0" <= character < "<"):
            output.append(ord(character))
            position += 1
            continue

        matched = False

        for keyword, token in KEYWORDS:
            if statement.startswith(keyword, position):
                output.append(token)
                position += len(keyword)
                matched = True

                if token == 0x83:
                    data_literal = True
                elif token == 0x8E:
                    rem_literal = True

                break

        if matched:
            continue

        if position >= warning_suppressed_until:
            warning_match = _warn_for_mixed_case_keyword(
                statement=statement, position=position, source_name=source_name,
                physical_line=physical_line, statement_column=statement_column)

            if warning_match is not None:
                warning, warning_length = warning_match
                warnings.append(warning)
                warning_suppressed_until = (position + warning_length)

        output.append(ord(character))
        position += 1

    return bytes(output), warnings


def parse_source(text: str, source_name: str) -> tuple[list[SourceLine], list[CompileWarning]]:
    parsed_lines: list[SourceLine] = []
    warnings: list[CompileWarning] = []

    previous_line_number = 0
    for physical_line, raw_line in enumerate(text.splitlines(), start=1):
        if raw_line == "":
            continue

        if len(raw_line) > 79:
            raise CompileError(source_name, physical_line, 80,
                (f"source line contains {len(raw_line)} characters; the TANEX BASIC limit is 79"))

        for column, character in enumerate(raw_line, start=1):
            if not (0x20 <= ord(character) <= 0x7E):
                raise CompileError(source_name, physical_line, column,
                    (f"non-printable ASCII character ${ord(character):02X}"))

        match = re.fullmatch(r"([0-9]+)(.*)", raw_line)

        if match is None:
            raise CompileError(source_name, physical_line, 1, "nonblank source line does not begin with a line number")

        digits = match.group(1)
        remainder = match.group(2)
        line_number = int(digits, 10)

        if not (1 <= line_number <= 63999):
            raise CompileError(source_name, physical_line, 1, (f"line number {line_number} is outside the valid range 1-63999"))

        if line_number <= previous_line_number:
            if line_number == previous_line_number:
                message = f"duplicate line number {line_number}"
            else:
                message = f"line number {line_number} is not greater than previous line number {previous_line_number}"

            raise CompileError(source_name, physical_line, 1, message)

        leading_spaces = len(remainder) - len(remainder.lstrip(" "))
        statement = remainder[leading_spaces:]
        statement_column = len(digits) + leading_spaces + 1

        if statement == "":
            raise CompileError(source_name, physical_line, len(raw_line) + 1, "line has no BASIC statement")

        tokenized, line_warnings = tokenize_statement(statement=statement, source_name=source_name, physical_line=physical_line, statement_column=statement_column)
        parsed_lines.append(SourceLine(physical_line=physical_line, line_number=line_number, statement_column=statement_column, statement=statement, tokenized=tokenized))
        warnings.extend(line_warnings)
        previous_line_number = line_number

    if not parsed_lines:
        raise CompileError(source_name, 1, 1, "source contains no numbered BASIC program lines")

    return parsed_lines, warnings


def build_payload(source_lines: Iterable[SourceLine], source_name: str) -> tuple[bytes, int]:
    payload = bytearray()
    current_address = LOAD_ADDRESS
    line_count = 0

    for source_line in source_lines:
        record_length = 5 + len(source_line.tokenized)
        next_address = current_address + record_length

        if next_address > 0xFFFF:
            raise CompileError(source_name, source_line.physical_line, 1, "tokenized program address exceeds 16-bit memory")

        payload.extend(struct.pack("<HH", next_address, source_line.line_number))
        payload.extend(source_line.tokenized)
        payload.append(0x00)

        current_address = next_address
        line_count += 1

    payload.extend(b"\x00\x00")

    return bytes(payload), line_count


def select_ram_top(first_free: int, source_name: str) -> tuple[int, str]:
    for ram_top, ram_label in RAM_TOPS:
        if first_free <= ram_top:
            return ram_top, ram_label

    raise CompileError(source_name, 1, 1, f"tokenized program ends at ${first_free - 1:04X}; it does not fit any supported BASIC RAM profile")


def verify_mtb(file_bytes: bytes) -> dict[str, int]:
    if len(file_bytes) < HEADER_SIZE:
        raise ValueError("MTB1 file is shorter than its header")

    (magic, header_size, flags, load_address, payload_length, first_free, ram_top, line_count, expected_crc32) = HEADER_STRUCT.unpack_from(file_bytes, 0)

    if magic != MAGIC:
        raise ValueError("invalid MTB1 magic or version")

    if header_size != HEADER_SIZE:
        raise ValueError("invalid MTB1 header size")

    if flags != 0:
        raise ValueError("unsupported MTB1 flags")

    if load_address != LOAD_ADDRESS:
        raise ValueError("invalid MTB1 load address")

    if len(file_bytes) != HEADER_SIZE + payload_length:
        raise ValueError("MTB1 file length does not match payload length")

    if first_free != LOAD_ADDRESS + payload_length:
        raise ValueError("MTB1 first-free address is inconsistent")

    if ram_top not in {value for value, _label in RAM_TOPS}:
        raise ValueError("invalid MTB1 RAM-top value")

    if first_free > ram_top:
        raise ValueError("MTB1 payload exceeds its required RAM profile")

    minimum_ram_top = next(candidate for candidate, _label in RAM_TOPS if first_free <= candidate)

    if ram_top != minimum_ram_top:
        raise ValueError("MTB1 RAM-top is not the smallest sufficient profile")

    payload = file_bytes[HEADER_SIZE:]
    actual_crc32 = zlib.crc32(payload) & 0xFFFFFFFF

    if actual_crc32 != expected_crc32:
        raise ValueError("MTB1 payload CRC32 mismatch")

    if len(payload) < 2:
        raise ValueError("MTB1 payload has no final zero link")

    offset = 0
    traversed_lines = 0
    previous_line_number = 0

    while True:
        if offset + 2 > len(payload):
            raise ValueError("MTB1 link traversal exceeds payload")

        next_address = struct.unpack_from("<H", payload, offset)[0]

        if next_address == 0:
            if offset != len(payload) - 2:
                raise ValueError("MTB1 final zero link is not at payload end")

            break

        if offset + 5 > len(payload):
            raise ValueError("truncated MTB1 BASIC line record")

        record_address = LOAD_ADDRESS + offset
        next_offset = next_address - LOAD_ADDRESS

        if next_address <= record_address:
            raise ValueError("MTB1 line link does not move forward")

        if not (offset + 5 <= next_offset <= len(payload) - 2):
            raise ValueError("MTB1 line link is outside the payload")

        if payload[next_offset - 1] != 0:
            raise ValueError("MTB1 BASIC line lacks its zero terminator")

        if 0 in payload[offset + 4 : next_offset - 1]:
            raise ValueError("MTB1 BASIC statement contains an embedded zero")

        line_number = struct.unpack_from("<H", payload, offset + 2)[0]

        if not (1 <= line_number <= 63999):
            raise ValueError("invalid MTB1 BASIC line number")

        if line_number <= previous_line_number:
            raise ValueError("MTB1 BASIC line numbers are not strictly increasing")

        previous_line_number = line_number
        traversed_lines += 1
        offset = next_offset

    if traversed_lines != line_count:
        raise ValueError("MTB1 header line count is inconsistent")

    return {
        "load_address": load_address,
        "payload_length": payload_length,
        "first_free": first_free,
        "ram_top": ram_top,
        "line_count": line_count,
        "crc32": expected_crc32,
    }


def compile_text(text: str, source_name: str = "<memory>") -> Compilation:
    source_lines, warnings = parse_source(text=text, source_name=source_name)
    payload, line_count = build_payload(source_lines=source_lines, source_name=source_name)
    first_free = LOAD_ADDRESS + len(payload)
    ram_top, ram_label = select_ram_top(first_free=first_free, source_name=source_name)
    crc32 = zlib.crc32(payload) & 0xFFFFFFFF
    header = HEADER_STRUCT.pack(MAGIC, HEADER_SIZE, 0, LOAD_ADDRESS, len(payload), first_free, ram_top, line_count, crc32)
    file_bytes = header + payload

    # The compiler verifies its own output before returning it.
    verify_mtb(file_bytes)

    return Compilation(
        source_name=source_name,
        payload=payload,
        file_bytes=file_bytes,
        line_count=line_count,
        first_free=first_free,
        ram_top=ram_top,
        ram_label=ram_label,
        crc32=crc32,
        warnings=tuple(warnings),
    )


def compile_path(source_path: Path) -> Compilation:
    raw_bytes = source_path.read_bytes()

    try:
        text = raw_bytes.decode("ascii")
    except UnicodeDecodeError as error:
        line, column = _ascii_error_position(raw_bytes, error.start)

        raise CompileError(str(source_path), line, column, "source is not 7-bit ASCII") from error

    return compile_text(text=text, source_name=str(source_path))


def main(argv: list[str] | None = None) -> int:
    argument_parser = argparse.ArgumentParser(description=("Compile plain-text Microtan BASIC source into the versioned MTB1 tokenized format."))
    argument_parser.add_argument("source", type=Path, help="plain-text .bas source file")
    argument_parser.add_argument("-o", "--output", type=Path, help="output .mtb file; defaults beside the source")
    argument_parser.add_argument("--check", action="store_true", help="validate and compile without writing an output file")
    arguments = argument_parser.parse_args(argv)
    output_path = (arguments.output if arguments.output is not None else arguments.source.with_suffix(".mtb"))

    if output_path.suffix.lower() != ".mtb":
        argument_parser.error("output filename must use .mtb")

    try:
        compilation = compile_path(arguments.source)
    except (OSError, CompileError, ValueError) as error:
        print(error, file=sys.stderr)
        return 1

    for warning in compilation.warnings:
        print(warning, file=sys.stderr)

    if not arguments.check:
        try:
            output_path.write_bytes(compilation.file_bytes)
        except OSError as error:
            print(error, file=sys.stderr)
            return 1

    final_address = compilation.first_free - 1
    action = "Checked" if arguments.check else "Compiled"

    print(f"{action} {arguments.source}: {compilation.line_count} lines, {len(compilation.payload)} payload bytes, "
        f"${LOAD_ADDRESS:04X}-${final_address:04X}, requires {compilation.ram_label} (top ${compilation.ram_top:04X}), CRC32 {compilation.crc32:08X}")

    if not arguments.check:
        print(f"Wrote {output_path} ({len(compilation.file_bytes)} bytes)")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())