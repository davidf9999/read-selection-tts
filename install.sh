#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
prefix="${PREFIX:-$HOME/.local}"
bindir="$prefix/bin"
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/read-selection-tts"
config_file="${READ_SELECTION_TTS_CONFIG:-$config_dir/config}"
voice_from_env="${READ_SELECTION_TTS_VOICE+x}"
voice="${READ_SELECTION_TTS_VOICE:-}"
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
  READ_SELECTION_TTS_VOICE=...  edge-tts voice (default: existing config or en-US-AriaNeural)
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
need python3
if [ "$install_shortcuts" -eq 1 ]; then
  need gsettings
fi
if [ "$missing" -ne 0 ]; then
  cat >&2 <<'MSG'

Install dependencies on Ubuntu/GNOME/Wayland:
  sudo apt install -y wl-clipboard mpv netcat-openbsd pipx python3
  pipx install edge-tts

Then rerun ./install.sh.
MSG
  exit 1
fi

config_parent="$(dirname "$config_file")"
if [ -z "${voice}" ] && [ -r "$config_file" ]; then
  voice="$(awk -F= '$1 == "READ_SELECTION_TTS_VOICE" {print substr($0, index($0, "=") + 1); exit}' "$config_file" 2>/dev/null || true)"
  voice="${voice%\"}"
  voice="${voice#\"}"
  voice="${voice%'}"
  voice="${voice#'}"
fi
case "${voice:-}" in
  ''|*[!A-Za-z0-9._-]*)
    if [ -n "$voice_from_env" ]; then
      echo "Invalid READ_SELECTION_TTS_VOICE: ${voice}" >&2
      exit 2
    fi
    voice="en-US-AriaNeural"
    ;;
esac

if [ "$install_shortcuts" -eq 1 ]; then
  if ! gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings >/dev/null 2>&1; then
    echo "Cannot access GNOME settings. Run install from your graphical GNOME desktop session, not under sudo or a headless shell." >&2
    exit 1
  fi
fi

mkdir -p "$bindir"
install -d -m 700 "$config_parent"
chmod 700 "$config_parent"
install -m 0755 "$script_dir/bin/read-selection-tts" "$bindir/read-selection-tts"
install -m 0755 "$script_dir/bin/pause-read-selection-tts" "$bindir/pause-read-selection-tts"
install -m 0755 "$script_dir/bin/continue-read-selection-tts" "$bindir/continue-read-selection-tts"
install -m 0755 "$script_dir/bin/stop-read-selection-tts" "$bindir/stop-read-selection-tts"

config_tmp="$(mktemp "${config_parent}/config.XXXXXX")"
python3 - "$config_file" "$config_tmp" "$voice" <<'INNERPY'
from pathlib import Path
import shlex
import sys
src = Path(sys.argv[1])
dst = Path(sys.argv[2])
voice = sys.argv[3]
lines = src.read_text().splitlines() if src.exists() else []
out = []
seen = False
for line in lines:
    if line.startswith('READ_SELECTION_TTS_VOICE='):
        if not seen:
            out.append('READ_SELECTION_TTS_VOICE=' + shlex.quote(voice))
            seen = True
    else:
        out.append(line)
if not seen:
    out.append('READ_SELECTION_TTS_VOICE=' + shlex.quote(voice))
dst.write_text('\n'.join(out) + '\n')
INNERPY
chmod 600 "$config_tmp"
mv -f "$config_tmp" "$config_file"

if [ "$install_shortcuts" -eq 1 ]; then
  base="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
  read_path="$base/read-selection-tts/"
  pause_path="$base/pause-read-selection-tts/"
  continue_path="$base/continue-read-selection-tts/"
  stop_path="$base/stop-read-selection-tts/"
  schema="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"

  get_shortcut_command() {
    gsettings get "${schema}$1" command 2>/dev/null | python3 -c 'import ast,sys; s=sys.stdin.read().strip(); print(ast.literal_eval(s) if s and s != "''" else "")' 2>/dev/null || true
  }

  can_own_path() {
    path="$1"
    command="$2"
    existing="$(get_shortcut_command "$path")"
    [ -z "$existing" ] || [ "$existing" = "$command" ]
  }

  add_paths=()
  skipped=0
  if can_own_path "$read_path" "$bindir/read-selection-tts"; then add_paths+=("$read_path"); else echo "Skipping existing non-owned shortcut path: $read_path" >&2; skipped=1; fi
  if can_own_path "$pause_path" "$bindir/pause-read-selection-tts"; then add_paths+=("$pause_path"); else echo "Skipping existing non-owned shortcut path: $pause_path" >&2; skipped=1; fi
  if can_own_path "$continue_path" "$bindir/continue-read-selection-tts"; then add_paths+=("$continue_path"); else echo "Skipping existing non-owned shortcut path: $continue_path" >&2; skipped=1; fi
  if [ -n "$stop_binding" ]; then
    if can_own_path "$stop_path" "$bindir/stop-read-selection-tts"; then add_paths+=("$stop_path"); else echo "Skipping existing non-owned shortcut path: $stop_path" >&2; skipped=1; fi
  else
    if [ "$(get_shortcut_command "$stop_path")" = "$bindir/stop-read-selection-tts" ]; then
      current="$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)"
      new_paths="$(paths="$current" REMOVE_PATHS="$stop_path" python3 - <<'INNERPY'
import ast, os
raw = os.environ['paths']
items = [] if raw.startswith('@as ') else ast.literal_eval(raw)
remove = set(filter(None, os.environ['REMOVE_PATHS'].split('|')))
items = [x for x in items if x not in remove]
print('[' + ', '.join(repr(x) for x in items) + ']' if items else '@as []')
INNERPY
)"
      gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_paths"
      gsettings reset "${schema}${stop_path}" name 2>/dev/null || true
      gsettings reset "${schema}${stop_path}" command 2>/dev/null || true
      gsettings reset "${schema}${stop_path}" binding 2>/dev/null || true
    fi
  fi

  if [ "${#add_paths[@]}" -gt 0 ]; then
    current="$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)"
    joined="$(IFS='|'; echo "${add_paths[*]}")"
    new_paths="$(paths="$current" ADD_PATHS="$joined" python3 - <<'INNERPY'
import ast, os
raw = os.environ['paths']
items = [] if raw.startswith('@as ') else ast.literal_eval(raw)
for value in filter(None, os.environ['ADD_PATHS'].split('|')):
    if value not in items:
        items.append(value)
print('[' + ', '.join(repr(x) for x in items) + ']')
INNERPY
)"
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_paths"
  fi

  configure_shortcut() {
    path="$1"
    name="$2"
    command="$3"
    binding="$4"
    if can_own_path "$path" "$command"; then
      gsettings set "${schema}${path}" name "$name"
      gsettings set "${schema}${path}" command "$command"
      gsettings set "${schema}${path}" binding "$binding"
    fi
  }

  configure_shortcut "$read_path" "Read selected text aloud" "$bindir/read-selection-tts" "$read_binding"
  configure_shortcut "$pause_path" "Pause read aloud" "$bindir/pause-read-selection-tts" "$pause_binding"
  configure_shortcut "$continue_path" "Continue read aloud" "$bindir/continue-read-selection-tts" "$continue_binding"
  if [ -n "$stop_binding" ]; then
    configure_shortcut "$stop_path" "Stop read aloud" "$bindir/stop-read-selection-tts" "$stop_binding"
  fi

  if [ "$skipped" -ne 0 ]; then
    echo "One or more GNOME shortcut paths already belonged to another command; those entries were left unchanged." >&2
  fi
fi

cat <<MSG
Installed read-selection-tts.

Use:
  ${read_binding}      read selected text
  ${pause_binding}     pause
  ${continue_binding}  continue

Config file:
  ${config_file}

Runtime/log directory:
  \${XDG_RUNTIME_DIR:-/tmp}/read-selection-tts
MSG
