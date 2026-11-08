# TANEX HRG Toolkit E2 ROM provenance

## Included image

- Firmware: TANEX High Resolution Graphics Toolkit
- Original designation: `hrgtkt.e2`
- CPU mapping: `$E800-$EFFF`
- TANEX socket: E2
- Size: 2,048 bytes
- CRC-32: `592C13DE`
- SHA-1: `544C2A3D58F07DFAA90F022F059129D6B8B659D6`

`hrg_toolkit_e2.hex` is a lossless textual conversion of the original binary,
with one uppercase hexadecimal byte per line in ascending CPU-address order.

## Public sources

- [Original archived binary](https://www.microtan.ukpc.net/Products/HRGTKT.BIN)
- [Original HRG Toolkit manual](https://www.microtan.ukpc.net/Products/HRGTK.pdf)
- [Archived Toolkit listing](https://www.microtan.ukpc.net/Products/ListHRGTKT.txt)
- [MAME Microtan driver at the corroborating revision](https://github.com/mamedev/mame/blob/1a326ed01c3629259abcf61a2a6bebf25858d376/src/mame/tangerine/microtan.cpp)

The archived binary and MAME identification agree on the size, CRC-32 and
SHA-1 above. Original Tangerine documentation governs the E2 socket and address
mapping; MAME is corroborating reference material rather than the hardware
specification.

## Selection decision

This HRG Toolkit is distinct from the TANEX BASIC Toolkit. The E2 socket offers
mutually exclusive `None`, `BASIC Toolkit` and `HRG Toolkit` selections, so only
one image may respond at `$E800-$EFFF`.
