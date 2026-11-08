# TANBUG 2.3 ROM provenance

## Included image

- Firmware: Tangerine TANBUG 2.3
- Original designation: `TANBUGv23.BIN`
- CPU mapping: `$F800-$FFFF`
- Size: 2,048 bytes
- CRC-32: `7F29845D`
- SHA-1: `DE277E942EEFA11A9A6DEFE3D7D03071D5100B68`
- SHA-256: `152516E9B201C9EF9FB71265DCF36D3A15432BC897A0472EA799813B39FC7DF8`

`tanbug_v23.hex` is a byte-for-byte textual conversion of the archived binary,
with one uppercase hexadecimal byte per line in ascending CPU-address order.

## Public sources

- [Microtan firmware archive](https://www.microtan.ukpc.net/pageFirmware.html)
- [Original `TANBUGv23.BIN`](https://www.microtan.ukpc.net/EPROMs/TANBUGv23.BIN)
- [TANBUG 2.3 assembly source](https://www.microtan.ukpc.net/EPROMs/TANBUGv2.3.asm)
- [TANBUG 2.3 assembled listing](https://www.microtan.ukpc.net/EPROMs/TANBUGv2.3.list)
- [TANBUG 2 manual](https://www.microtan.ukpc.net/EPROMs/TANBUGv2.pdf)

The binary, source and listing are original firmware evidence. The conversion
preserves all 2,048 bytes, including the vectors at the top of the 6502 address
space.
