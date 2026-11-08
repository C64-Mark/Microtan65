# Microtan character-generator data provenance

## Included image

- Original designation: `charset.rom`
- Size: 2,048 bytes
- CRC-32: `3B3C5360`
- SHA-1: `A3A2F74149107F8B8F35B15069C71F3AA843D12F`
- SHA-256: `C275E34B6FD4024351A85AB3C7494045A705294FC51E8640997F5C2179D8EDF9`

`microtan_charset.hex` is a lossless textual conversion of the preserved ROM
dump, with one uppercase hexadecimal byte per line in its original order.

## Public sources

- [geo255 preserved ROM dump at the pinned revision](https://github.com/geo255/microtan65/raw/572b8783574d4c049f302d50346331d9c84102b7/assets/charset.rom)
- [geo255 Microtan emulator repository](https://github.com/geo255/microtan65)
- [MAME Microtan driver at the corroborating revision](https://github.com/mamedev/mame/blob/1a326ed01c3629259abcf61a2a6bebf25858d376/src/mame/tangerine/microtan.cpp)

The geo255 dump and MAME identification agree on the size, CRC-32 and SHA-1.
They corroborate the preserved character data; no emulator source code was
copied.

The original MT001 schematic establishes the DM8678 character-generator
arrangement: each of the 128 character codes has sixteen stored row bytes, and
display-data bit 7 is not part of the character-ROM address.
