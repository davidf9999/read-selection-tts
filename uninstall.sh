#!/usr/bin/env bash
set -euo pipefail

prefix="${PREFIX:-$HOME/.local}"
bindir="$prefix/bin"
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/read-selection-tts"
config_file="${READ_SELECTION_TTS_CONFIG:-$config_dir/config}"
runtime_base="${READ_SELECTION_TTS_RUNTIME_DIR:-${XDG_RUNTIME_DIR:-/tmp}/read-selection-tts}"
pidfile="${READ_SELECTION_TTS_PIDFILE:-$runtime_base/mpv.pid}"
sock="${READ_SELECTION_TTS_SOCKET:-$runtime_base/mpv.sock}"
media="${READ_SELECTION_TTS_MEDIA:-$runtime_base/read-selection.mp3}"
log="${READ_SELECTION_TTS_LOG:-$runtime_base/read-selection-tts.log}"

if [ -s "$pidfile" ]; then
  pid="$(cat "$pidfile" 2>/dev/null || true)"
  if [ -n "${pid:-}" ] && kill -0 "$pid" 2>/dev/null; then
    kill -TERM "$pid" 2>/dev/null || true
  fi
fi
rm -f "$pidfile" "$sock" "$media" "$log" "$log.old" "$runtime_base"/read-selection.*.txt "$runtime_base"/read-selection.*.mp3

rm -f "$bindir/read-selection-tts" \
      "$bindir/pause-read-selection-tts" \
      "$bindir/continue-read-selection-tts" \
      "$bindir/stop-read-selection-tts"

if command -v gsettings >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
  base="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
  schema="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"

  get_shortcut_command() {
    gsettings get "${schema}$1" command 2>/dev/null | python3 -c 'import ast,sys; s=sys.stdin.read().strip(); print(ast.literal_eval(s) if s and s != "''" else "")' 2>/dev/null || true
  }

  remove_paths=()
  for spec in \
    "$base/read-selection-tts/|$bindir/read-selection-tts" \
    "$base/pause-read-selection-tts/|$bindir/pause-read-selection-tts" \
    "$base/continue-read-selection-tts/|$bindir/continue-read-selection-tts" \
    "$base/stop-read-selection-tts/|$bindir/stop-read-selection-tts"
  do
    path="${spec%%|*}"
    command="${spec#*|}"
    if [ "$(get_shortcut_command "$path")" = "$command" ]; then
      remove_paths+=("$path")
    fi
  done

  if [ "${#remove_paths[@]}" -gt 0 ]; then
    current="$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)"
    joined="$(IFS='|'; echo "${remove_paths[*]}")"
    new_paths="$(paths="$current" REMOVE_PATHS="$joined" python3 - <<'INNERPY'
import ast, os
raw = os.environ['paths']
items = [] if raw.startswith('@as ') else ast.literal_eval(raw)
remove = set(filter(None, os.environ['REMOVE_PATHS'].split('|')))
items = [x for x in items if x not in remove]
print('[' + ', '.join(repr(x) for x in items) + ']' if items else '@as []')
INNERPY
)"
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_paths"
    for path in "${remove_paths[@]}"; do
      gsettings reset "${schema}${path}" name 2>/dev/null || true
      gsettings reset "${schema}${path}" command 2>/dev/null || true
      gsettings reset "${schema}${path}" binding 2>/dev/null || true
    done
  fi
fi

rm -f "$config_file"
rmdir "$config_dir" 2>/dev/null || true
rmdir "$runtime_base" 2>/dev/null || true

echo "Uninstalled read-selection-tts."
