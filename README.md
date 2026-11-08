<a href="https://en.wikipedia.org/wiki/Tangerine_Microtan_65#/media/File:Tangerine_Microtan_65_In_System_Rack_(white_bg).jpg">
  <img align="right" width="320" src="https://upload.wikimedia.org/wikipedia/commons/5/54/Tangerine_Microtan_65_In_System_Rack_%28white_bg%29.jpg" alt="Tangerine Microtan 65 in its System Rack">
</a>

# Microtan 65 for MiSTer

## About this core

This project recreates the Tangerine Microtan 65 home computer as an FPGA core
for MiSTer. The aim is to preserve the character of the original 1979 machine,
from its 750 kHz 6502, 1 KiB base configuration and TANBUG monitor through to
useful contemporary expansions such as TANEX memory, Microsoft BASIC, XBUG,
high-resolution graphics and sound hardware.

Development was AI-assisted, with OpenAI Codex supporting research, test design
and implementation guidance while I applied, reviewed and tested every change. 
The core was built in small, independently verifiable stages rather than produced 
as a one-pass port. Subsystems were unit-tested as they were introduced, machine 
timing received dedicated simulation coverage, and integration was repeatedly 
checked through Quartus Prime and TimeQuest before being exercised on MiSTer hardware.

Implementation decisions follow an evidence-led approach. Original Tangerine
schematics and manuals take priority, supported by original firmware, observed
machine behaviour, later reconstructions and established emulators. The result
is intended to be both practical to use and faithful to the documented
Microtan architecture.

## Features

- 750 kHz 6502-compatible processor with TANBUG 2.3 and XBUG.
- Original 32 x 16 character display and 64 x 64 chunky graphics, with the
  documented red, green, blue and white display colours.
- Selectable 1, 8, 16, 32 or 48 KiB RAM profiles; 1 KiB is the stock default.
- Microsoft BASIC, BASIC Toolkit and HRG Toolkit ROM support.
- Selectable high-resolution graphics card in Phantom or Block Slot 1 mode.
- TANEX VIA support, optional second VIA and joystick input through VIA port A.
- ASCII keyboard and MT006 hexadecimal keypad modes, plus gamepad and optional
  keyboard-joystick control.
- Selectable Bulldog AY or original Space Invasion sound hardware.
- Loading of HEX programs, M65 snapshots, compiled MTB BASIC programs and T65
  cassette images, including files selected directly from ZIP archives.
- Separate warm reset, warm reset with screen clear, and cold reset with RAM
  and screen clear.

## Installation and Quick Start

Copy the release `.rbf` file to the MiSTer SD card's `_Computer` directory,
then select **Microtan65** from the MiSTer computer cores menu. No external BIOS
or firmware files are required.

The initial configuration represents a stock 1 KiB Microtan. This is useful for
authentic hardware testing, but most expanded software requires more memory. For
general use, open the OSD with F12, enter **Hardware & ROM**, select **8K** or the
memory size required by the software, and use MiSTer's **Save Settings** command
if that choice should become the default.

The core starts in the TANBUG monitor and displays its `%` prompt. If a clean
display and cleared RAM are wanted before beginning, select **Cold Reset & Clear
Screen** from the OSD. The keyboard defaults to ASCII mode and the remaining
selectable E2 ROM, HRG card, sound hardware and second VIA are disabled until
selected.

## Controls

In **ASCII** keyboard mode, letters, numbers and punctuation produce their
normal Microtan ASCII characters. Caps Lock starts enabled so TANBUG commands
are upper-case; Shift, Caps Lock and Control otherwise operate normally.

| Host key | Microtan key or action |
| --- | --- |
| Enter | Return |
| Tab / Escape / Space | Corresponding Microtan key |
| Backspace | Delete/Rubout |
| Delete | Backspace |
| Insert or numeric keypad Enter | Line Feed |
| Pause/Break | Break |
| Right Alt/AltGr plus a held key | Repeat that key |

The Backspace and Delete assignments deliberately follow modern editing habits:
host Backspace performs the Microtan's destructive Delete/Rubout operation,
while host Delete provides the original non-destructive Backspace character.

In **MT006 Keypad** mode, host keys `0`-`9` and `A`-`F` select the matching
hexadecimal keys. Enter selects **CR/SP**, Backspace selects **LF/DEL**, and
either Shift key operates the keypad Shift key.

A MiSTer gamepad is presented through TANEX VIA 0 port A. Its directional
controls provide Up, Down, Left and Right; buttons 1, 2 and 3 provide Shift,
Space and Control respectively. When **Keyboard Joystick** is enabled, the
cursor keys and Left Shift, Space and Left Control add the same controls. The
physical gamepad remains active whether this option is enabled or not.

## OSD Options

The main OSD provides the four software selectors described in the next
section, together with the following input choices:

| Setting | Choices |
| --- | --- |
| Keyboard | ASCII / MT006 Keypad |
| Keyboard Joystick | No / Yes |

**Video Settings** contains:

| Setting | Choices |
| --- | --- |
| Aspect Ratio | Original / Full Screen |
| Display Colour | White / Red / Green / Blue |

**Hardware & ROM** contains:

| Setting | Choices |
| --- | --- |
| Memory | 1K / 8K / 16K / 32K / 48K |
| E2 ROM | None / BASIC Toolkit / HRG Toolkit |
| HRG Card | None / Phantom / Block Slot 1 |
| Sound Hardware | None / Bulldog AY / Space Invasion |
| VIA 1 | None / Installed |

The reset entries all close the OSD:

| Reset | Effect |
| --- | --- |
| Warm Reset | Resets the machine while retaining RAM and the display |
| Warm Reset & Clear Screen | Retains ordinary RAM but clears the display |
| Cold Reset & Clear Screen | Clears installed RAM and the display before reset |

Use MiSTer's **Save Settings** command to retain the selected configuration.
After changing a hardware or ROM profile, reset the machine before starting the
associated software.

## Loading Software

MiSTer can select supported files directly from ZIP archives. Before loading,
choose the RAM, ROM and expansion hardware required by the program.

### HEX programs

**Load HEX** accepts the annotated Microtan/Zillion HEX format and writes the
program into RAM. HEX files do not start automatically: when loading finishes,
enter the program's documented TANBUG start command, such as `G0420`.

### M65 snapshots

**Load M65 Snapshot** restores the saved RAM, display and processor state, then
resumes the snapshot automatically. Loading from the stock 1K setting promotes
the active memory profile to the 8K required by the format.

### MTB BASIC programs

Select sufficient RAM and any toolkit required by the program. At the TANBUG
prompt enter `BAS`, press Enter at the **MEMORY SIZE?** and **TERMINAL WIDTH?**
prompts, and wait for BASIC's `OK`. Select **Load MTB Program**, wait for `OK`
to return, then enter `RUN`. MTB files are compiled BASIC programs and cannot
be loaded directly from TANBUG.

### T65 cassette images

T65 files are replayed through the emulated XBUG cassette input rather than
copied directly into RAM. Start the appropriate cassette command before
selecting **Load T65 Tape** from the OSD:

- For a machine-code file, enter `F` at TANBUG to select FAST mode, then enter
  `F,<filename>` using its embedded XBUG filename. Select the T65 file while
  XBUG is waiting, then use the program's documented `Gxxxx` start command.
- For a BASIC `.B` file, enter BASIC and type `LOAD`. Answer `Y` to **FAST?**,
  press Enter without typing anything at **EXAM?**, and enter the filename
  without `.B` at **FILENAME?**. Select the T65 file while BASIC is waiting;
  when `OK` returns, enter `RUN`.

A collection of tested HEX, M65, MTB and T65 software is available from the
[Microtan 65 Software Archive](https://archive.org/details/microtan65).

## Conversion Tools

The public repository includes two self-contained Python 3 utilities in its
`scripts` directory. They use only the Python standard library:

- `microtan_wav_to_t65.py` validates a Microtan XBUG cassette recording and
  converts it to a FAST T65 image for the core.
- `microtan_basic_compiler.py` compiles a plain-text Microtan BASIC listing into
  an MTB program image.

Command syntax, accepted input and example workflows are documented in
[`scripts/README.md`](scripts/README.md).

## Building from Source

The proven build environment is Intel Quartus Prime Lite 17.0.2 Build 602 with
Cyclone V device support. Other Quartus versions have not been validated.

Open `Microtan65.qpf` in Quartus and select **Processing > Start Compilation**.
Alternatively, run the following from the project root in a Quartus command
shell:

```text
quartus_sh --flow compile Microtan65
```

A successful full compilation creates `output_files/Microtan65.rbf`. Copy this
file to the MiSTer SD card's `_Computer` directory; release builds may be renamed
to include their build date.

## Validation

The final design passed its complete simulation regression and a full Quartus
17.0.2 compilation with zero errors and positive TimeQuest setup, hold,
recovery, removal and minimum-pulse-width slack. The resulting RBF was exercised
on MiSTer hardware across boot and reset, video, keyboard and joystick input,
memory and ROM profiles, HRG, both sound systems and every supported loader. All
clean HEX, M65, MTB and T65 packages selected for the release corpus operated as
expected.

## Known Limitations and Future Work

This release concentrates on the documented and physically validated machine
profiles. Possible later work includes:

- TANDOS and virtual disk support;
- direct cassette input through the MiSTer ADC and cassette recording/output;
- authentic slow CUTS playback in addition to the current validated FAST T65
  path;
- configurable gamepad mappings for software that directly scans particular
  MT006 keypad keys;
- 64 KiB memory and additional TANBUS peripherals; and
- investigation of earlier TANBUG versions and further optional ROMs.

The present core supports up to 48 KiB RAM and targets TANBUG 2.3. WAV cassette
recordings must be converted to T65 on a host computer before loading.

## Sources, Credits, Licensing and Reuse

This core could not have been produced without the exceptional preservation,
research and engineering work already carried out by the Microtan and FPGA
communities. Particular thanks are due to:

- Tangerine Computer Systems and Tansoft, whose original manuals, schematics
  and firmware remain the primary evidence for the machine;
- the maintainers and contributors of the
  [Microtan archive](https://www.microtan.ukpc.net/), which preserves an
  invaluable collection of original documentation, firmware and software;
- [Geoff MacDonald](https://www.geoff.org.uk/microtan/) for his extensive
  Microtan research, documentation and software, together with the
  [geo255 emulator source](https://github.com/geo255/microtan65);
- [Barry Graham](https://microtan.thegrahamfamily.me.uk/) for documenting and
  sharing his detailed modern Microtan reconstruction work;
- the [MAME project](https://github.com/mamedev/mame) and
  [hoglet67's FPGA work](https://github.com/hoglet67/Microtan65-FPGA), which
  provided valuable secondary implementation references;
- the [MiSTer project template](https://github.com/MiSTer-devel/Template_MiSTer)
  and the wider MiSTer community;
- Daniel Wallner, Mike Johnson, Wolfgang Scherr, Morten Leikvoll and the other
  contributors to the [T65 CPU](https://github.com/mist-devel/T65);
- Mike Johnson for the M6522 VIA implementation, retained through
  [BeebFpga](https://github.com/hoglet67/BeebFpga); and
- José Tejada (Jotego) and contributors for the
  [JT49 sound core](https://github.com/jotego/jt49).

Original Tangerine evidence takes precedence in this project; emulator and
existing FPGA sources were used as secondary references rather than machine
specifications.

Project-authored HDL and utilities are licensed under GPL-2.0-or-later unless
an individual file states otherwise. Third-party components retain their own
copyright and licence notices: JT49 is GPL-3.0-or-later, while T65 and M6522
carry their included permissive notices. Anyone is welcome to study, adapt and
redistribute this core. No personal attribution to me is requested, but all 
upstream copyright, licence and credit notices must be preserved and their terms 
followed.

The header photograph is by Ian Dunster, via
[Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Tangerine_Microtan_65_In_System_Rack_(white_bg).jpg),
and is licensed under
[CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/).
