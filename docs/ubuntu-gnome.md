# Ubuntu GNOME Wayland Notes

This project relies on the Wayland primary selection:

```bash
wl-paste --primary
```

In most GNOME terminals, selecting text with the mouse updates the primary
selection. If it does not, copy normally with `Ctrl+Shift+C` and adapt the
script to use `wl-paste` instead of `wl-paste --primary`.

GNOME custom shortcuts are stored under:

```text
org.gnome.settings-daemon.plugins.media-keys custom-keybindings
```

The installer appends these shortcut paths instead of replacing unrelated
custom shortcuts.

## Current Limitation

Pause/resume works by generating a temporary MP3 and playing it with `mpv` over
a Unix IPC socket. Very long selections may take a few seconds before playback
starts because the full audio file is generated first.
