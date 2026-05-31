---
name: Bug report
about: Report a problem with selected-text read-aloud, shortcuts, install, or playback
title: "Bug: "
labels: bug
assignees: ""
---

## What happened?

Describe the problem and what you expected instead.

## Environment

- Distribution and version:
- Desktop environment and version:
- Session type: Wayland or X11? Run `printf '%s\n' "$XDG_SESSION_TYPE"`
- Install method: git clone, release archive, or other?
- Voice setting, if changed:

## Reproduction Steps

1.
2.
3.

## Logs and Checks

Please run these and paste relevant output. Remove private selected text before sharing logs.

```bash
runtime_dir="${XDG_RUNTIME_DIR:+$XDG_RUNTIME_DIR/read-selection-tts}"
runtime_dir="${runtime_dir:-/tmp/read-selection-tts-$(id -u)}"
tail -n 80 "$runtime_dir/read-selection-tts.log" 2>/dev/null || true
command -v wl-paste edge-tts mpv python3
wl-paste --primary | head -c 200
```

## Additional Context

Screenshots, terminal output, or anything unusual about your keyboard shortcuts/audio setup.
