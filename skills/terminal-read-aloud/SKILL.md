---
name: terminal-read-aloud
description: Read selected or piped text aloud on Ubuntu/GNOME/Wayland using high-quality Microsoft Edge neural TTS voices, with keyboard shortcuts to pause, continue, and stop playback.
when_to_use: Use when the user wants selected text or piped text read aloud on a Linux GNOME/Wayland desktop, wants to install or manage read-selection-tts, or asks to have text spoken via a command-line pipe.
user-invocable: true
---

# Terminal Read Aloud

Read selected or piped text aloud on Ubuntu/GNOME/Wayland.

**Requirements:** Ubuntu 22.04+ · GNOME · Wayland · `wl-clipboard` · `mpv` · `pipx` · `python3`

**Privacy:** Selected text is sent to Microsoft's online Edge TTS service. Do not use for secrets or sensitive text.

## Install

1. Confirm the user is on Linux GNOME/Wayland:

   ```bash
   printf '%s\n' "$XDG_SESSION_TYPE"
   ```

2. Install system dependencies:

   ```bash
   sudo apt install -y wl-clipboard mpv pipx python3
   pipx install edge-tts
   echo "$HOME/.local/bin" >> ~/.bashrc && export PATH="$HOME/.local/bin:$PATH"
   ```

3. Clone the repo and install:

   ```bash
   git clone https://github.com/davidf9999/read-selection-tts.git
   cd read-selection-tts
   ./install.sh
   ```

## Use

Select text with the mouse, then press `Ctrl+Alt+R` to hear it read aloud.

| Shortcut | Action |
|---|---|
| `Ctrl+Alt+R` | Read selected text |
| `Ctrl+Alt+S` | Pause |
| `Ctrl+Alt+C` | Continue |

To add an optional stop shortcut:

```bash
READ_SELECTION_TTS_STOP_BINDING='<Control><Alt>x' ./install.sh
```

## Agent / scripted use

Pipe any text directly — no mouse selection needed:

```bash
printf 'Hello from an agent\n' | read-selection-tts --stdin
```

This works from any shell, cron job, or AI agent that can run bash on the user's desktop.

## Debug

```bash
runtime_dir="${XDG_RUNTIME_DIR:+$XDG_RUNTIME_DIR/read-selection-tts}"
runtime_dir="${runtime_dir:-/tmp/read-selection-tts-$(id -u)}"
cat "$runtime_dir/read-selection-tts.log"
wl-paste --primary
command -v edge-tts mpv python3 wl-paste
```

## Uninstall

```bash
./uninstall.sh
```
