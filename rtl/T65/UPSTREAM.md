# T65 CPU Core Provenance

Upstream project: `mist-devel/T65`

Upstream repository: https://github.com/mist-devel/T65

Imported revision:

    7027ad169553911b1d55ce6d220364e7c8595b94

Retrieved: 2026-09-20

T65 is retained as the CPU implementation selected for the Microtan65 MiSTer core.

The upstream files and their copyright and reuse notices must be retained. Project integration uses T65 in NMOS 6502 mode (`Mode = "00"`) with decimal arithmetic enabled.

Known considerations:

- The upstream source documents limitations in its NMI handling. Microtan delayed-NMI behaviour must therefore be explicitly tested before being considered compatible.
- The 65C02 and 65C816 modes are incomplete and are not used by this project.
- The upstream source requires CPU write data to be returned on the data-input path during write cycles for correct behaviour of some undocumented opcodes.

Arlet’s 6502 and the retained hoglet67 Microtan FPGA implementation are independent, credited comparison references.