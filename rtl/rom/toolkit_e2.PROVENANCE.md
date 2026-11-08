# TANEX BASIC Toolkit E2 ROM provenance

## Included image

- Firmware: TANEX BASIC Toolkit
- Original designation: `toolkit.e2`
- CPU mapping: `$E800-$EFFF`
- TANEX socket: E2
- Size: 2,048 bytes
- CRC-32: `BD87FD34`
- SHA-1: `F41895DF4A733DDDFAF1C89ECFF5040ADDCAB804`

`toolkit_e2.hex` contains one uppercase hexadecimal byte per line in ascending
CPU-address order.

## Byte source and public verification

The image was extracted from offsets `$2800-$2FFF` of geo255's preserved
16 KiB `microtan_original.rom` container. The pinned container has SHA-1
`3EE0755D9C1532F12D6C9CA98FDCC3F1AE33A48C`.

- [Pinned geo255 source container](https://github.com/geo255/microtan65/raw/572b8783574d4c049f302d50346331d9c84102b7/assets/rom_archive/microtan_original.rom)
- [geo255 Microtan emulator repository](https://github.com/geo255/microtan65)
- [MAME Microtan driver at the corroborating revision](https://github.com/mamedev/mame/blob/1a326ed01c3629259abcf61a2a6bebf25858d376/src/mame/tangerine/microtan.cpp)
- [Public Microtan Toolkit archive](https://www.microtan.ukpc.net/pageFirmware.html#Toolkits)

The geo255 bytes and MAME identification agree on the size, CRC-32 and SHA-1.
Original Tangerine TANEX documentation remains the specification for the E2
socket and its address mapping.

## Selection decision

The public archive's `TOOLKIT_E2.INT` is a different variant and is not used by
this core. The included image is the BASIC Toolkit version on which geo255 and
MAME agree. E2 remains an optional socket and defaults to `None`.
