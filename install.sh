#!/usr/bin/env bash
set -euo pipefail

prefix="${PREFIX:-$HOME/.local}"
bindir="$prefix/bin"
voice="${READ_SELECTION_TTS_VOICE:-en-US-AriaNeural}"
read_binding="${READ_SELECTION_TTS_READ_BINDING:-<Control><Alt>r}"
pause_binding="${READ_SELECTION_TTS_PAUSE_BINDING:-<Control><Alt>s}"
continue_binding="${READ_SELECTION_TTS_CONTINUE_BINDING:-<Control><Alt>c}"
stop_binding="${READ_SELECTION_TTS_STOP_BINDING:-}"
install_shortcuts=1

usage() {
  cat <<USAGE
Usage: ./install.sh [--no-shortcuts]

Installs selected-text read-aloud helpers to ~/.local/bin and, by default,
registers GNOME custom keyboard shortcuts:
  ${read_binding}      Read selected text
  ${pause_binding}     Pause
  ${continue_binding}  Continue

Optional environment:
  PREFIX=/path                  install prefix (default: ~/.local)
  READ_SELECTION_TTS_VOICE=...  edge-tts voice (default: ${voice})
  READ_SELECTION_TTS_*_BINDING  override GNOME shortcut bindings
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --no-shortcuts) install_shortcuts=0 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing dependency: $1" >&2
    missing=1
  fi
}

missing=0
need wl-paste
need edge-tts
need mpv
need nc
if [ "$install_shortcuts" -eq 1 ]; then
  need gsettings
fi
if [ "$missing" -ne 0 ]; then
  cat >&2 <<'MSG'

Install dependencies on Ubuntu/GNOME/Wayland:
  sudo apt install -y wl-clipboard mpv netcat-openbsd pipx
  pipx install edge-tts

Then rerun ./install.sh.
MSG
  exit 1
fi

mkdir -p "$bindir"
install -m 0755 bin/read-selection-tts "$bindir/read-selection-tts"
install -m 0755 bin/pause-read-selection-tts "$bindir/pause-read-selection-tts"
install -m 0755 bin/continue-read-selection-tts "$bindir/continue-read-selection-tts"
install -m 0755 bin/stop-read-selection-tts "$bindir/stop-read-selection-tts"

if [ "$install_shortcuts" -eq 1 ]; then
  base="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
  read_path="$base/read-selection-tts/"
  pause_path="$base/pause-read-selection-tts/"
  continue_path="$base/continue-read-selection-tts/"
  stop_path="$base/stop-read-selection-tts/"

  current="$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)"
  new_paths="$(paths="$current" READ_PATH="$read_path" PAUSE_PATH="$pause_path" CONTINUE_PATH="$continue_path" STOP_PATH="$stop_path" STOP_BINDING="$stop_binding" python3 - <<'PY'
import ast, os
raw = os.environ["paths"]
if raw.startswith("@as "):
    items = []
else:
    items = ast.literal_eval(raw)
for key in ("READ_PATH", "PAUSE_PATH", "CONTINUE_PATH"):
    value = os.environ[key]
    if value not in items:
        items.append(value)
if os.environ.get("STOP_BINDING"):
    value = os.environ["STOP_PATH"]
    if value not in items:
        items.append(value)
print("[" + ", ".join(repr(x) for x in items) + "]")
PY
)"
  gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_paths"

  schema="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"
  gsettings set "${schema}${read_path}" name "Read selected text aloud"
  gsettings set "${schema}${read_path}" command "$bindir/read-selection-tts"
  gsettings set "${schema}${read_path}" binding "$read_binding"

  gsettings set "${schema}${pause_path}" name "Pause read aloud"
  gsettings set "${schema}${pause_path}" command "$bindir/pause-read-selection-tts"
  gsettings set "${schema}${pause_path}" binding "$pause_binding"

  gsettings set "${schema}${continue_path}" name "Continue read aloud"
  gsettings set "${schema}${continue_path}" command "$bindir/continue-read-selection-tts"
  gsettings set "${schema}${continue_path}" binding "$continue_binding"

  if [ -n "$stop_binding" ]; then
    gsettings set "${schema}${stop_path}" name "Stop read aloud"
    gsettings set "${schema}${stop_path}" command "$bindir/stop-read-selection-tts"
    gsettings set "${schema}${stop_path}" binding "$stop_binding"
  fi
fi

cat <<MSG
Installed read-selection-tts.

Use:
  ${read_binding}      read selected text
  ${pause_binding}     pause
  ${continue_binding}  continue

Log file:
  /tmp/read-selection-tts.log
MSG
