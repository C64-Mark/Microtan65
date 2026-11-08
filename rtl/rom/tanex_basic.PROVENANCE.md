# TANEX BASIC ROM provenance

## Included image

- Firmware: 10 KiB TANEX Microsoft BASIC
- CPU mapping: `$C000-$E7FF`
- Size: 10,240 bytes
- CRC-32: `8AD5E615`
- SHA-1: `72D9C3193891DE1F19622B50620B8B60D813B081`

`tanex_basic.hex` contains one uppercase hexadecimal byte per line in ascending
CPU-address order. It contains BASIC only; it does not include the E2 Toolkit,
XBUG or TANBUG ROMs.

## Byte source and public verification

The image was extracted from offsets `$0000-$27FF` of geo255's preserved
16 KiB `microtan_original.rom` container. The pinned container has SHA-1
`3EE0755D9C1532F12D6C9CA98FDCC3F1AE33A48C`.

- [Pinned geo255 source container](https://github.com/geo255/microtan65/raw/572b8783574d4c049f302d50346331d9c84102b7/assets/rom_archive/microtan_original.rom)
- [Public Microtan firmware archive](https://www.microtan.ukpc.net/pageFirmware.html#BASIC)
- [Original `BASIC_J2.BIN`](https://www.microtan.ukpc.net/EPROMs/BASIC_J2.BIN)
- [Original `BASIC_H2.BIN`](https://www.microtan.ukpc.net/EPROMs/BASIC_H2.BIN)
- [Original `BASIC_D3.BIN`](https://www.microtan.ukpc.net/EPROMs/BASIC_D3.BIN)
- [MAME Microtan driver at the corroborating revision](https://github.com/mamedev/mame/blob/1a326ed01c3629259abcf61a2a6bebf25858d376/src/mame/tangerine/microtan.cpp)

The three component identities are:

| CPU range | Original name | Size | CRC-32 | SHA-1 |
|---|---|---:|---|---|
| `$C000-$CFFF` | `basl.j2` | 4,096 | `3E09D384` | `15A98941A672FF16242CC73F1DCF1D81FCCD8910` |
| `$D000-$DFFF` | `basm.h2` | 4,096 | `75105113` | `C6FEA4D65B7C52F43AA1589CACE9467349A0F290` |
| `$E000-$E7FF` | `bash.d3` | 2,048 | `EE6E8412` | `7E1BCA84BAB79D94A4AB8554D23E2BC28CCD0384` |

The public archive, geo255 container and MAME identification agree on these
component bytes. Original Tangerine TANEX documentation remains the address-map
specification; the emulator sources are corroborating evidence only.
