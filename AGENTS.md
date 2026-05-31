# AGENTS.md

## Project Overview

This is a small Bash-based GNOME/Wayland utility for reading selected text aloud.
It uses:

- `wl-paste` for the Wayland primary selection
- `edge-tts` for online TTS generation
- `mpv` for playback and pause/continue IPC
- `gsettings` for GNOME shortcut installation

## Development Commands

Run before committing:

```bash
shellcheck -x install.sh uninstall.sh bin/* lib/common.sh tests/smoke.sh
./tests/smoke.sh
```

## Style

- Bash is allowed; keep scripts simple and shellcheck-clean.
- Use `set -euo pipefail` in executable scripts.
- Prefer shared behavior in `lib/common.sh` over duplicating shell functions.
- Keep runtime paths under `$XDG_RUNTIME_DIR/read-selection-tts` or the configured runtime directory.
- Preserve user-owned GNOME shortcuts; do not overwrite unrelated custom shortcuts.

## Security And Privacy

- Do not log selected text.
- Do not pass selected text via process arguments.
- Do not send secrets or sensitive documents to `edge-tts`.
- Treat runtime directory safety as important: reject symlinks, non-directories, and directories not owned by the user.
- Be careful with pidfiles: avoid killing unrelated processes.

## Testing Notes

Smoke tests should avoid requiring a real GNOME session, real `edge-tts`, or real `mpv` where possible. Prefer fake commands on `PATH`.
