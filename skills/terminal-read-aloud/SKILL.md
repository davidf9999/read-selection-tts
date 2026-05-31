---
name: terminal-read-aloud
description: Install and maintain the read-selection-tts helper for GNOME/Wayland selected-text read-aloud using edge-tts, mpv, and keyboard shortcuts.
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

## Shortcuts

- `Ctrl+Alt+R`: read selected text.
- `Ctrl+Alt+S`: pause.
- `Ctrl+Alt+C`: continue.

## Debug

Check:

```bash
cat "${XDG_RUNTIME_DIR:-/tmp}/read-selection-tts/read-selection-tts.log"
wl-paste --primary
command -v edge-tts mpv python3 wl-paste
```

## Privacy Warning

This helper sends selected text to Microsoft's online Edge TTS service via
`edge-tts`. Do not use it for secrets or sensitive text.
