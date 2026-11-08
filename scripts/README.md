# Microtan 65 Conversion Tools

These two command-line tools prepare software for use with the Microtan 65
MiSTer core. They require Python 3.10 or later and use only the Python standard
library; no extra packages need to be installed.

Run the examples below from PowerShell, Command Prompt or a terminal. Replace
the example filenames with the paths to your own files.

## WAV cassette recording to T65

`microtan_wav_to_t65.py` decodes one complete Microtan XBUG cassette file from
a WAV recording, validates its framing and checksums, and creates a FAST T65
image for the core.

The WAV input must be uncompressed, mono, signed 16-bit PCM. If necessary, use
an audio editor to convert a stereo or differently encoded recording first.

To create `game.t65` in the current directory:

```text
python microtan_wav_to_t65.py game.wav
```

To choose a different output path or filename:

```text
python microtan_wav_to_t65.py game.wav converted/game.t65
```

The converter reports the embedded XBUG filename, address range, checksum and
CRC32 when decoding succeeds. It stops with an error if the recording cannot be
decoded or validated. Existing output files are never overwritten.

Load the resulting file from **Load T65 Tape** in the core. The commands needed
before playback differ for machine-code and BASIC recordings; see
[Loading Software](../README.md#loading-software) in the main README.

## Plain-text BASIC to MTB

`microtan_basic_compiler.py` tokenizes a plain-text TANEX BASIC listing and
creates an MTB program image that can be injected into BASIC by the core.

Source files must use 7-bit ASCII and contain numbered BASIC program lines in
strictly increasing order. Line numbers must be from 1 to 63999, each source
line is limited to 79 characters, and BASIC keywords should be uppercase.

To create an MTB file beside the source file:

```text
python microtan_basic_compiler.py game.bas
```

To choose a different output path or filename:

```text
python microtan_basic_compiler.py game.bas -o converted/game.mtb
```

To validate and tokenize a listing without writing an output file:

```text
python microtan_basic_compiler.py game.bas --check
```

The compiler reports the tokenized address range, minimum supported RAM profile
and CRC32. Errors include their source line and column. Lowercase text that
resembles a BASIC keyword is preserved literally and produces a warning because
keyword matching is case-sensitive.

To use the result, enter BASIC, answer its startup prompts, select
**Load MTB Program**, wait for `OK`, and enter `RUN`. The full sequence is given
under [Loading Software](../README.md#loading-software).

## Command help

Either tool can display its complete command-line syntax:

```text
python microtan_wav_to_t65.py --help
python microtan_basic_compiler.py --help
```
