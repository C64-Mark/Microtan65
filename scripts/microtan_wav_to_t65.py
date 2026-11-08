#!/usr/bin/env python3

from __future__ import annotations

import argparse
import array
import struct
import sys
import wave
import zlib
from dataclasses import dataclass
from pathlib import Path
from typing import Sequence


MAGIC = b"T65\x1A"
VERSION = 1
RECORD_TYPE_XBUG = 1

ENCODING_FAST = 1
ENCODING_CUTS = 2
VALID_ENCODINGS = (ENCODING_FAST, ENCODING_CUTS)

HEADER_SIZE = 32
FRAMING_XBUG = 1
CHECKSUM_COPIES = 16
FLAGS_NONE = 0

HEADER_PREFIX_STRUCT = struct.Struct("<4sBBBB8sHHIBBBB")
HEADER_STRUCT = struct.Struct("<4sBBBB8sHHIBBBBI")


class T65Error(ValueError):
    pass


@dataclass(frozen=True)
class T65Record:
    filename: bytes
    start_address: int
    payload: bytes
    playback_encoding: int = ENCODING_FAST

    def __post_init__(self) -> None:
        if not isinstance(self.filename, bytes):
            raise T65Error("XBUG filename must be bytes")

        if len(self.filename) != 8:
            raise T65Error("XBUG filename must contain exactly 8 bytes")

        if not isinstance(self.payload, bytes):
            raise T65Error("payload must be bytes")

        if not self.payload:
            raise T65Error("payload must not be empty")

        if not 0 <= self.start_address <= 0xFFFF:
            raise T65Error("start address is outside the 6502 address space")

        if self.end_address > 0xFFFF:
            raise T65Error("payload extends beyond the 6502 address space")

        if self.playback_encoding not in VALID_ENCODINGS:
            raise T65Error(
                f"unsupported playback encoding {self.playback_encoding}"
            )

    @property
    def end_address(self) -> int:
        return self.start_address + len(self.payload) - 1

    @property
    def additive_checksum(self) -> int:
        return sum(self.payload) & 0xFF

    def header_prefix(self) -> bytes:
        return HEADER_PREFIX_STRUCT.pack(
            MAGIC,
            VERSION,
            RECORD_TYPE_XBUG,
            self.playback_encoding,
            HEADER_SIZE,
            self.filename,
            self.start_address,
            self.end_address,
            len(self.payload),
            self.additive_checksum,
            FRAMING_XBUG,
            CHECKSUM_COPIES,
            FLAGS_NONE,
        )

    @property
    def crc32(self) -> int:
        return zlib.crc32(
            self.header_prefix() + self.payload
        ) & 0xFFFFFFFF

    def to_bytes(self) -> bytes:
        return (
            self.header_prefix()
            + struct.pack("<I", self.crc32)
            + self.payload
        )


def parse_t65(file_bytes: bytes) -> T65Record:
    if not isinstance(file_bytes, bytes):
        raise T65Error("file data must be bytes")

    if len(file_bytes) < HEADER_SIZE:
        raise T65Error("file is shorter than the 32-byte T65 header")

    (
        magic,
        version,
        record_type,
        playback_encoding,
        header_size,
        filename,
        start_address,
        end_address,
        payload_length,
        stored_checksum,
        framing,
        checksum_copies,
        flags,
        stored_crc32,
    ) = HEADER_STRUCT.unpack_from(file_bytes)

    if magic != MAGIC:
        raise T65Error("invalid T65 magic")

    if version != VERSION:
        raise T65Error(f"unsupported T65 version {version}")

    if record_type != RECORD_TYPE_XBUG:
        raise T65Error(f"unsupported T65 record type {record_type}")

    if playback_encoding not in VALID_ENCODINGS:
        raise T65Error(
            f"unsupported playback encoding {playback_encoding}"
        )

    if header_size != HEADER_SIZE:
        raise T65Error(f"unsupported T65 header size {header_size}")

    if framing != FRAMING_XBUG:
        raise T65Error(f"unsupported framing profile {framing}")

    if checksum_copies != CHECKSUM_COPIES:
        raise T65Error(
            f"unsupported checksum-copy count {checksum_copies}"
        )

    if flags != FLAGS_NONE:
        raise T65Error(f"unsupported T65 flags ${flags:02X}")

    expected_file_size = HEADER_SIZE + payload_length

    if len(file_bytes) != expected_file_size:
        raise T65Error(
            "file size does not match the declared payload length"
        )

    if end_address < start_address:
        raise T65Error("end address is below the start address")

    expected_payload_length = end_address - start_address + 1

    if payload_length != expected_payload_length:
        raise T65Error(
            "payload length does not match the inclusive address range"
        )

    payload = file_bytes[HEADER_SIZE:]

    calculated_checksum = sum(payload) & 0xFF

    if stored_checksum != calculated_checksum:
        raise T65Error(
            "additive checksum mismatch: "
            f"stored=${stored_checksum:02X}, "
            f"calculated=${calculated_checksum:02X}"
        )

    calculated_crc32 = zlib.crc32(
        file_bytes[:28] + payload
    ) & 0xFFFFFFFF

    if stored_crc32 != calculated_crc32:
        raise T65Error(
            "CRC32 mismatch: "
            f"stored={stored_crc32:08X}, "
            f"calculated={calculated_crc32:08X}"
        )

    return T65Record(
        filename=filename,
        start_address=start_address,
        payload=payload,
        playback_encoding=playback_encoding,
    )


MINIMUM_LEADER_HALF_CYCLES = 1000


class WavDecodeError(T65Error):
    pass


@dataclass(frozen=True)
class DecodedWaveRecord:
    record: T65Record
    source_encoding: int
    checksum_copies: int
    leader_half_cycles: int
    sample_rate: int


def _decode_frame(
    bits: list[int],
    position: int,
) -> int | None:
    frame = bits[position:position + 13]

    if len(frame) != 13:
        return None

    if frame[0] != 0:
        return None

    if sum(frame[1:10]) & 1 != 1:
        return None

    if frame[10:] != [1, 1, 1]:
        return None

    return sum(
        frame[1 + bit] << bit
        for bit in range(8)
    )


def _parse_header(
    values: list[int | None],
) -> tuple[bytes, int, int, int]:
    if len(values) != 12 or any(
        value is None
        for value in values
    ):
        raise WavDecodeError("invalid XBUG header framing")

    header = [int(value) for value in values]

    if not all(
        0x20 <= value <= 0x7E
        for value in header[:8]
    ):
        raise WavDecodeError(
            "XBUG filename contains non-printable bytes"
        )

    filename = bytes(header[:8])
    end_address = (header[8] << 8) | header[9]
    start_address = (header[10] << 8) | header[11]

    if end_address < start_address:
        raise WavDecodeError(
            "XBUG end address is below its start address"
        )

    payload_length = end_address - start_address + 1

    return (
        filename,
        start_address,
        end_address,
        payload_length,
    )


def _finish_record(
    values: list[int],
    source_encoding: int,
    leader_half_cycles: int,
    sample_rate: int,
) -> DecodedWaveRecord:
    (
        filename,
        start_address,
        _,
        payload_length,
    ) = _parse_header(values[:12])

    required_values = 12 + payload_length + 1

    if len(values) < required_values:
        raise WavDecodeError(
            "record ended before its complete payload and checksum"
        )

    payload = bytes(
        values[12:12 + payload_length]
    )

    checksum_values = values[12 + payload_length:]

    if not checksum_values:
        raise WavDecodeError(
            "record has no surviving checksum copy"
        )

    if len(set(checksum_values)) != 1:
        raise WavDecodeError(
            "repeated checksum copies disagree"
        )

    stored_checksum = checksum_values[0]
    calculated_checksum = sum(payload) & 0xFF

    if stored_checksum != calculated_checksum:
        raise WavDecodeError(
            "payload checksum mismatch: "
            f"stored=${stored_checksum:02X}, "
            f"calculated=${calculated_checksum:02X}"
        )

    record = T65Record(
        filename=filename,
        start_address=start_address,
        payload=payload,
        playback_encoding=ENCODING_FAST,
    )

    return DecodedWaveRecord(
        record=record,
        source_encoding=source_encoding,
        checksum_copies=len(checksum_values),
        leader_half_cycles=leader_half_cycles,
        sample_rate=sample_rate,
    )


def _decode_cuts_record(
    classifications: list[int | None],
    leader_end: int,
    leader_half_cycles: int,
    sample_rate: int,
) -> DecodedWaveRecord:
    bits: list[int] = []
    position = leader_end

    while (
        position < len(classifications)
        and classifications[position] is not None
    ):
        classification = int(classifications[position])
        run_end = position + 1

        while (
            run_end < len(classifications)
            and classifications[run_end] == classification
        ):
            run_end += 1

        run_length = run_end - position
        unit_length = 16 if classification == 1 else 8
        bit_count = round(run_length / unit_length)

        if (
            bit_count < 1
            or abs(run_length - bit_count * unit_length) > 2
        ):
            break

        bits.extend(
            [classification] * bit_count
        )

        position = run_end

    header_values = [
        _decode_frame(bits, frame * 13)
        for frame in range(12)
    ]

    (
        _,
        _,
        _,
        payload_length,
    ) = _parse_header(header_values)

    bit_position = 12 * 13

    while (
        bit_position < len(bits)
        and bits[bit_position] == 1
    ):
        bit_position += 1

    values = [
        int(value)
        for value in header_values
    ]

    for _ in range(payload_length):
        value = _decode_frame(bits, bit_position)

        if value is None:
            raise WavDecodeError(
                "CUTS payload framing ended before "
                "the declared address range"
            )

        values.append(value)
        bit_position += 13

    while True:
        value = _decode_frame(bits, bit_position)

        if value is None:
            break

        values.append(value)
        bit_position += 13

    return _finish_record(
        values,
        source_encoding=ENCODING_CUTS,
        leader_half_cycles=leader_half_cycles,
        sample_rate=sample_rate,
    )


def _decode_fast_record(
    classifications: list[int | None],
    leader_end: int,
    leader_half_cycles: int,
    sample_rate: int,
) -> DecodedWaveRecord:
    half_cycles = classifications[leader_end:]

    def frame_at(position: int) -> int | None:
        if position + 24 >= len(half_cycles):
            return None

        frame_bits = [
            half_cycles[position + 2 * bit]
            for bit in range(13)
        ]

        if any(
            bit is None
            for bit in frame_bits
        ):
            return None

        return _decode_frame(
            [int(bit) for bit in frame_bits],
            0,
        )

    def find_next_frame(
        position: int,
        search_limit: int = 512,
    ) -> tuple[int, int] | None:
        search_end = min(
            len(half_cycles) - 24,
            position + search_limit,
        )

        for candidate in range(position, search_end):
            value = frame_at(candidate)

            if value is not None:
                return candidate, value

        return None

    values: list[int] = []
    position = 0

    for _ in range(12):
        match = find_next_frame(position)

        if match is None:
            raise WavDecodeError(
                "FAST header framing is incomplete"
            )

        frame_position, value = match
        values.append(value)
        position = frame_position + 26

    (
        _,
        _,
        _,
        payload_length,
    ) = _parse_header(values)

    for _ in range(payload_length):
        match = find_next_frame(position)

        if match is None:
            raise WavDecodeError(
                "FAST payload framing ended before "
                "the declared address range"
            )

        frame_position, value = match
        values.append(value)
        position = frame_position + 26

    while True:
        match = find_next_frame(
            position,
            search_limit=80,
        )

        if match is None:
            break

        frame_position, value = match
        checksum_values = values[12 + payload_length:]

        if (
            checksum_values
            and value != checksum_values[-1]
        ):
            break

        values.append(value)
        position = frame_position + 26

    return _finish_record(
        values,
        source_encoding=ENCODING_FAST,
        leader_half_cycles=leader_half_cycles,
        sample_rate=sample_rate,
    )


def _read_wav(
    path: Path,
) -> tuple[int, array.array[int]]:
    try:
        with wave.open(str(path), "rb") as wav_file:
            if wav_file.getnchannels() != 1:
                raise WavDecodeError(
                    "WAV input must be mono"
                )

            if wav_file.getsampwidth() != 2:
                raise WavDecodeError(
                    "WAV input must use signed 16-bit PCM"
                )

            if wav_file.getcomptype() != "NONE":
                raise WavDecodeError(
                    "WAV input must be uncompressed PCM"
                )

            sample_rate = wav_file.getframerate()
            samples = array.array(
                "h",
                wav_file.readframes(
                    wav_file.getnframes()
                ),
            )

    except wave.Error as error:
        raise WavDecodeError(
            f"invalid WAV input: {error}"
        ) from error

    if sys.byteorder == "big":
        samples.byteswap()

    if not samples:
        raise WavDecodeError(
            "WAV input contains no samples"
        )

    return sample_rate, samples


def decode_xbug_wav(
    path: str | Path,
) -> DecodedWaveRecord:
    wav_path = Path(path)
    sample_rate, samples = _read_wav(wav_path)

    peak = max(
        max(samples),
        -min(samples),
    )

    threshold = max(
        500,
        min(3000, peak // 5),
    )

    state = 1 if samples[0] >= threshold else 0
    edges: list[int] = []

    for index, sample in enumerate(samples[1:], 1):
        if state == 0 and sample >= threshold:
            state = 1
            edges.append(index)

        elif state == 1 and sample <= -threshold:
            state = 0
            edges.append(index)

    if len(edges) < 2:
        raise WavDecodeError(
            "WAV input contains no usable cassette waveform"
        )

    periods = [
        following - current
        for current, following in zip(
            edges,
            edges[1:],
        )
    ]

    short_half_period = sample_rate / (2 * 2400)
    long_half_period = sample_rate / (2 * 1200)
    boundary = short_half_period * 1.6

    classifications: list[int | None] = []

    for period in periods:
        if (
            short_half_period * 0.5
            <= period
            < boundary
        ):
            classifications.append(1)

        elif (
            boundary
            <= period
            <= long_half_period * 1.75
        ):
            classifications.append(0)

        else:
            classifications.append(None)

    leaders: list[tuple[int, int, int]] = []
    position = 0

    while position < len(classifications):
        classification = classifications[position]
        run_end = position + 1

        while (
            run_end < len(classifications)
            and classifications[run_end] == classification
        ):
            run_end += 1

        run_length = run_end - position

        if (
            classification == 1
            and run_length >= MINIMUM_LEADER_HALF_CYCLES
        ):
            leaders.append(
                (
                    position,
                    run_end,
                    run_length,
                )
            )

        position = run_end

    if not leaders:
        raise WavDecodeError(
            "no XBUG cassette leader was found"
        )

    errors: list[str] = []

    for _, leader_end, leader_length in leaders:
        for decoder in (
            _decode_cuts_record,
            _decode_fast_record,
        ):
            try:
                return decoder(
                    classifications,
                    leader_end,
                    leader_length,
                    sample_rate,
                )

            except WavDecodeError as error:
                errors.append(str(error))

    detail = "; ".join(errors[-4:])

    raise WavDecodeError(
        "unable to decode a valid XBUG cassette record"
        + (f": {detail}" if detail else "")
    )


def _encoding_name(encoding: int) -> str:
    if encoding == ENCODING_FAST:
        return "FAST"

    if encoding == ENCODING_CUTS:
        return "CUTS"

    return f"unknown-{encoding}"


def convert_wav_to_t65(
    input_path: str | Path,
    output_path: str | Path,
) -> DecodedWaveRecord:
    source = Path(input_path)
    destination = Path(output_path)

    if destination.exists():
        raise FileExistsError(
            f"output file already exists: {destination}"
        )

    decoded = decode_xbug_wav(source)
    file_bytes = decoded.record.to_bytes()

    verified_record = parse_t65(file_bytes)

    if verified_record != decoded.record:
        raise T65Error(
            "internal T65 serialization round-trip failed"
        )

    with destination.open("xb") as output_file:
        output_file.write(file_bytes)

    return decoded


def build_argument_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Decode one Microtan XBUG WAV recording and "
            "write a validated version-1 FAST .t65 file."
        )
    )

    parser.add_argument(
        "input_wav",
        type=Path,
        help="source mono signed-16-bit PCM WAV file",
    )

    parser.add_argument(
        "output_t65",
        nargs="?",
        type=Path,
        help=(
            "optional output .t65 file; defaults to the input filename "
            "with a .t65 extension in the current directory; existing "
            "files are not overwritten"
        ),
    )

    return parser


def main(
    arguments: Sequence[str] | None = None,
) -> int:
    parser = build_argument_parser()
    options = parser.parse_args(arguments)
    output_path = options.output_t65

    if output_path is None:
        output_path = Path.cwd() / options.input_wav.with_suffix(".t65").name

    try:
        decoded = convert_wav_to_t65(
            options.input_wav,
            output_path,
        )

    except (
        FileExistsError,
        OSError,
        T65Error,
    ) as error:
        print(
            f"error: {error}",
            file=sys.stderr,
        )
        return 1

    record = decoded.record

    print(
        f"Decoded {options.input_wav}: "
        f"{record.filename.decode('ascii')}, "
        f"${record.start_address:04X}-${record.end_address:04X}, "
        f"{len(record.payload)} payload bytes, "
        f"source {_encoding_name(decoded.source_encoding)}, "
        f"{decoded.checksum_copies} checksum copies"
    )

    print(
        f"Wrote {output_path}: "
        f"{len(record.to_bytes())} bytes, "
        f"playback FAST, "
        f"checksum ${record.additive_checksum:02X}, "
        f"CRC32 {record.crc32:08X}"
    )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

