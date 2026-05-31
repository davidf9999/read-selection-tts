#!/usr/bin/env bash
set -euo pipefail

prefix="${PREFIX:-$HOME/.local}"
bindir="$prefix/bin"

rm -f "$bindir/read-selection-tts" \
      "$bindir/pause-read-selection-tts" \
      "$bindir/continue-read-selection-tts" \
      "$bindir/stop-read-selection-tts"

if command -v gsettings >/dev/null 2>&1; then
  base="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
  current="$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)"
  new_paths="$(paths="$current" python3 - <<'PY'
import ast, os
raw = os.environ["paths"]
if raw.startswith("@as "):
    items = []
else:
    items = ast.literal_eval(raw)
remove = {
    "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/read-selection-tts/",
    "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/pause-read-selection-tts/",
    "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/continue-read-selection-tts/",
    "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/stop-read-selection-tts/",
}
items = [x for x in items if x not in remove]
print("[" + ", ".join(repr(x) for x in items) + "]" if items else "@as []")
PY
)"
  gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_paths"
fi

pkill -TERM -f "mpv.*/tmp/read-selection-tts-mpv.sock" 2>/dev/null || true
rm -f /tmp/read-selection-tts.mp3 /tmp/read-selection-tts-mpv.sock

echo "Uninstalled read-selection-tts."
