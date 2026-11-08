# XBUG 5.3 ROM provenance

## Included image

- Firmware: Tangerine XBUG 5.3
- Archive designation: `XBUG5_3`
- CPU mapping: `$F000-$F7FF`
- TANEX socket: G2
- Size: 2,048 bytes
- CRC-32: `28DC4646`
- SHA-1: `968D60428A63DDF8D8656B8BEF2C456EC8E86622`

`xbug_v53.hex` is a lossless conversion of the archived Intel-format image,
with one uppercase hexadecimal byte per line in ascending CPU-address order.
All Intel-record checksums were validated during conversion.

## Public sources

- [Microtan firmware archive](https://www.microtan.ukpc.net/pageFirmware.html#XBug)
- [Original `XBUG5_3.INT`](https://www.microtan.ukpc.net/XBUG5_3.INT)
- [Original XBUG assembly listing](https://www.microtan.ukpc.net/XBugList.pdf)
- [Original XBUG manual](https://www.microtan.ukpc.net/XBugManual.pdf)

The Intel image contains offsets `$0000-$07FF`, corresponding to CPU addresses
`$F000-$F7FF`, followed by its terminating record. The first machine bytes also
match the published listing at `$F000`.

## Selection decision

The geo255 composite contains a separate 1.5 MHz tape-timing variant, so it is
not used for this original-rate core. XBUG 5.3 is selected from the public
firmware archive and is supported by its corresponding Tangerine listing.
