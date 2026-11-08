# M6522 VIA Core Provenance

Upstream project: `hoglet67/BeebFpga`

Upstream repository: https://github.com/hoglet67/BeebFpga

Imported revision:

    f0c99eb72b5d3e7ba01e9f7f5938fbc4a899a576

Imported source:

    src/common/m6522.vhd

Imported source SHA-256:

    60B1150F1F32556D6EA3A2D0FB65DCB3F3F9DEAB001934D1B7CAFC3157B85961

Retrieved: 2026-10-26

The source identifies the original implementation as MikeJ's VIA model,
copyright March 2003. Its embedded notice explicitly permits redistribution
and modification in source and synthesized forms subject to retention of the
copyright notice, conditions and disclaimer.

The upstream revision describes this as version 005 and records that it passes
the VICE VIA tests. It remains an implementation dependency rather than an
architectural specification. Original Tangerine TANEX documentation and the
MCS6522 hardware behaviour govern Microtan integration.

Known considerations:

- The source was originally described as a VIC-20 VIA implementation, although
  the `M6522` entity exposes a general 6522 interface.
- The source notes uncertainty around some shift-register behaviour.
- Correct Microtan integration requires deliberate handling of `CLK`,
  `ENA_4`, `I_P2_H`, active-low reset and active-low IRQ.
- Port, timer, interrupt and control-line behaviour must be validated
  independently before VIA integration is accepted.