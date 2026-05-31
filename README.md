# read-selection-tts

Tiny GNOME/Wayland helper for reading selected text aloud with high-quality
Edge neural TTS.

It is intentionally not a screen reader. It does one narrow thing:

1. Select text anywhere that populates the Wayland primary selection.
2. Press `Ctrl+Alt+R` to read it aloud.
3. Press `Ctrl+Alt+S` to pause.
4. Press `Ctrl+Alt+C` to continue.

## Why

Linux already has screen readers, browser read-aloud extensions, and local TTS
engines. This project exists for a narrower workflow:

- better voice quality than `spd-say`/eSpeak on many systems;
- less intrusive than Orca when you only want selected text read aloud;
- works with terminal selections and other GNOME/Wayland primary selections;
- pause/resume shortcuts without adopting a full accessibility stack.

## Privacy

This uses [`edge-tts`](https://pypi.org/project/edge-tts/), which sends the
selected text to Microsoft's online speech service. Do not use it for secrets,
private documents, credentials, or sensitive personal information.

If you need offline speech, look at Piper/Mimic3-based tools such as Voluble or
VoxFree instead.

## Limitations

- **Single Language/Voice:** The tool uses a single voice configured in `~/.config/read-selection-tts/config`. Reading text in a language different from the configured voice will result in unnatural pronunciation (a strong accent) or playback failure.
- **Latency on Long Selections:** Since `edge-tts` must generate the entire audio file before `mpv` starts playback, very long selections may take a few seconds before the audio begins.

## Requirements

Tested on Ubuntu GNOME Wayland.

Runtime dependencies:

- `wl-paste` from `wl-clipboard`
- `edge-tts` from `pipx install edge-tts`
- `mpv`
- `gsettings` for GNOME shortcut installation

Install dependencies on Ubuntu:

```bash
sudo apt install -y wl-clipboard mpv pipx python3
pipx install edge-tts
```

Make sure `~/.local/bin` is on your `PATH`.

## Install

```bash
git clone https://github.com/davidf9999/read-selection-tts.git && cd read-selection-tts && ./install.sh
```

Avoid `curl | bash` installs for this project: the installer copies versioned
files from the repository and should run from a checked-out release.

Default shortcuts:

- `Ctrl+Alt+R`: read selected text
- `Ctrl+Alt+S`: pause
- `Ctrl+Alt+C`: continue

The installer preserves existing GNOME custom shortcuts, appends its own, and leaves shortcut paths alone if they already belong to another command.

## Use

Select text with the mouse, then press `Ctrl+Alt+R`.

Pause and continue:

```text
Ctrl+Alt+S
Ctrl+Alt+C
```

Start a new selection with `Ctrl+Alt+R`; it replaces the previous read-aloud
audio.

Scripted or agent-triggered speech can use standard input instead of the
Wayland primary selection:

```bash
printf 'Hello from an agent\n' | read-selection-tts --stdin
```

## Configuration

Choose a different voice:

```bash
READ_SELECTION_TTS_VOICE=en-GB-SoniaNeural ./install.sh
```

The selected voice is persisted in `~/.config/read-selection-tts/config`, so GNOME shortcuts use it after the installing terminal closes. Reinstalling without `READ_SELECTION_TTS_VOICE` preserves the existing voice and any other config lines.

Override shortcut bindings:

```bash
READ_SELECTION_TTS_READ_BINDING='<Super><Alt>r' ./install.sh
```

List available voices:

```bash
edge-tts --list-voices | less
```

## Uninstall

```bash
./uninstall.sh
```

## Troubleshooting

Check the log:

```bash
runtime_dir="${XDG_RUNTIME_DIR:+$XDG_RUNTIME_DIR/read-selection-tts}"
runtime_dir="${runtime_dir:-/tmp/read-selection-tts-$(id -u)}"
cat "$runtime_dir/read-selection-tts.log"
```

If the shortcut fires but no audio plays, verify:

```bash
command -v wl-paste edge-tts mpv python3
wl-paste --primary
tmp="$(mktemp --suffix=.mp3)"
edge-tts --voice en-US-AriaNeural --text "test" --write-media "$tmp"
mpv "$tmp"
```

If `edge-tts` is not found from a GNOME shortcut but works in your terminal,
ensure `~/.local/bin` is on `PATH`. The installed scripts set a conservative
`PATH`, so this should normally work.

## Alternatives

- Orca: full GNOME screen reader. Better for complete UI accessibility, more
  intrusive for casual selected-text reading.
- Voluble: GNOME extension using Piper; closer to this project and worth trying
  if you want offline speech.
- VoxFree: offline Ubuntu/GNOME voice toolkit.
- Browser extensions: excellent inside browsers, not a general terminal/system
  selected-text workflow.
