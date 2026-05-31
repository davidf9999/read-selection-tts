---
name: terminal-read-aloud
description: Install and maintain read-selection-tts, a GNOME/Wayland selected-text read-aloud helper using edge-tts, mpv, and keyboard shortcuts.
tags: [tts, text-to-speech, audio, speech, linux, gnome, wayland, terminal, accessibility, agent-tool]
platforms: [linux]
dependencies: [wl-clipboard, mpv, python3, edge-tts]
---

# Terminal Read Aloud

Use this skill when the user wants selected terminal or desktop text read aloud
on Ubuntu/GNOME/Wayland with good voice quality and simple keyboard shortcuts.

## Install

1. Confirm the user is on Linux GNOME/Wayland:

   ```bash
   printf '%s\n' "$XDG_SESSION_TYPE"
   ```

2. Ensure dependencies are installed:

   ```bash
   sudo apt install -y wl-clipboard mpv pipx python3
   pipx install edge-tts
   ```

3. Clone the repo and run:

   ```bash
   ./install.sh
   ```

## Agent Usage

For scripted or agent-triggered speech without touching the Wayland primary selection:

```bash
printf 'Hello from an agent\n' | read-selection-tts --stdin
```

## Shortcuts

- `Ctrl+Alt+R`: read selected text.
- `Ctrl+Alt+S`: pause.
- `Ctrl+Alt+C`: continue.

## Debug

Check:

```bash
runtime_dir="${XDG_RUNTIME_DIR:+$XDG_RUNTIME_DIR/read-selection-tts}"
runtime_dir="${runtime_dir:-/tmp/read-selection-tts-$(id -u)}"
cat "$runtime_dir/read-selection-tts.log"
wl-paste --primary
command -v edge-tts mpv python3 wl-paste
```

## Privacy Warning

This helper sends selected text to Microsoft's online Edge TTS service via
`edge-tts`. Do not use it for secrets or sensitive text.
