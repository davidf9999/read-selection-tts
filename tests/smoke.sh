#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

for file in bin/* install.sh uninstall.sh; do
  bash -n "$file"
done

grep -q "edge-tts" bin/read-selection-tts
grep -q -- "--file" bin/read-selection-tts
if grep -q -- "--text" bin/read-selection-tts; then
  echo "selected text must not be passed via process arguments" >&2
  exit 1
fi
grep -q "input-ipc-server" bin/read-selection-tts
grep -q -- "--stdin" bin/read-selection-tts
grep -q "READ_SELECTION_TTS_CONFIG" lib/common.sh
grep -q "XDG_RUNTIME_DIR.*read-selection-tts" lib/common.sh
grep -q "set_property.*pause.*true" bin/pause-read-selection-tts
grep -q "set_property.*pause.*false" bin/continue-read-selection-tts
grep -q "socket.AF_UNIX" bin/pause-read-selection-tts
grep -q "socket.AF_UNIX" bin/continue-read-selection-tts
if grep -R "nc -U\|need nc" bin install.sh README.md skills >/dev/null; then
  echo "netcat must not be required for mpv IPC" >&2
  exit 1
fi
if grep -R "pkill -f" bin install.sh uninstall.sh >/dev/null; then
  echo "pkill -f must not be used for mpv cleanup" >&2
  exit 1
fi
if grep -RE "/tmp/read-selection-tts\.(mp3|log)|/tmp/read-selection-tts-mpv" bin install.sh uninstall.sh README.md SECURITY.md docs skills >/dev/null; then
  echo "fixed shared /tmp read-selection file paths must not be documented or used" >&2
  exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
stubdir="$tmp/stubs"
mkdir -p "$stubdir"

for cmd in wl-paste edge-tts mpv; do
  cat >"$stubdir/$cmd" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
  chmod +x "$stubdir/$cmd"
done

cat >"$stubdir/gsettings" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
state="${GSETTINGS_MOCK_STATE:?}"
log="${GSETTINGS_MOCK_LOG:?}"
mkdir -p "$state"
printf '%s\n' "$*" >>"$log"
key() {
  printf '%s' "$1|$2" | base64 | tr '/+=' '___'
}
if [ "$1" = "get" ]; then
  schema="$2"
  name="$3"
  if [ "$schema" = "org.gnome.settings-daemon.plugins.media-keys" ] && [ "$name" = "custom-keybindings" ]; then
    cat "$state/custom-keybindings" 2>/dev/null || printf '@as []\n'
    exit 0
  fi
  file="$state/$(key "$schema" "$name")"
  cat "$file" 2>/dev/null || printf "''\n"
  exit 0
fi
if [ "$1" = "set" ]; then
  schema="$2"
  name="$3"
  shift 3
  value="$*"
  if [ "$schema" = "org.gnome.settings-daemon.plugins.media-keys" ] && [ "$name" = "custom-keybindings" ]; then
    printf '%s\n' "$value" >"$state/custom-keybindings"
    exit 0
  fi
  file="$state/$(key "$schema" "$name")"
  python3 - "$value" >"$file" <<'INNERPY'
import sys
print(repr(sys.argv[1]))
INNERPY
  exit 0
fi
if [ "$1" = "reset" ]; then
  schema="$2"
  name="$3"
  rm -f "$state/$(key "$schema" "$name")"
  exit 0
fi
exit 2
STUB
chmod +x "$stubdir/gsettings"

PATH="$stubdir:$PATH" PREFIX="$tmp/prefix" XDG_CONFIG_HOME="$tmp/config" ./install.sh --no-shortcuts
test -x "$tmp/prefix/bin/read-selection-tts"
test -x "$tmp/prefix/bin/pause-read-selection-tts"
test -x "$tmp/prefix/bin/continue-read-selection-tts"
test -x "$tmp/prefix/bin/stop-read-selection-tts"
test -f "$tmp/prefix/lib/read-selection-tts/common.sh"
test -f "$tmp/config/read-selection-tts/config"
test "$(stat -c %a "$tmp/config/read-selection-tts/config")" = "600"

GSETTINGS_MOCK_STATE="$tmp/gsettings-state" GSETTINGS_MOCK_LOG="$tmp/gsettings.log" \
  PATH="$stubdir:$PATH" PREFIX="$tmp/prefix" XDG_CONFIG_HOME="$tmp/config" \
  READ_SELECTION_TTS_VOICE="en-GB-SoniaNeural" READ_SELECTION_TTS_STOP_BINDING="<Control><Alt>x" ./install.sh

grep -q "READ_SELECTION_TTS_VOICE=en-GB-SoniaNeural" "$tmp/config/read-selection-tts/config"
printf 'READ_SELECTION_TTS_RATE=+5%%\n' >>"$tmp/config/read-selection-tts/config"
grep -q "read-selection-tts/" "$tmp/gsettings-state/custom-keybindings"
grep -q "stop-read-selection-tts/" "$tmp/gsettings-state/custom-keybindings"

GSETTINGS_MOCK_STATE="$tmp/gsettings-state" GSETTINGS_MOCK_LOG="$tmp/gsettings.log" \
  PATH="$stubdir:$PATH" PREFIX="$tmp/prefix" XDG_CONFIG_HOME="$tmp/config" ./install.sh
grep -q "READ_SELECTION_TTS_VOICE=en-GB-SoniaNeural" "$tmp/config/read-selection-tts/config"
grep -q "READ_SELECTION_TTS_RATE=+5%" "$tmp/config/read-selection-tts/config"
if grep -q "stop-read-selection-tts/" "$tmp/gsettings-state/custom-keybindings"; then
  echo "stale stop shortcut was not removed on reinstall without stop binding" >&2
  exit 1
fi

foreign="$tmp/gsettings-foreign"
mkdir -p "$foreign"
printf "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/read-selection-tts/']\n" >"$foreign/custom-keybindings"
foreign_key="$(printf '%s' "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/read-selection-tts/|command" | base64 | tr '/+=' '___')"
printf "'/usr/bin/foreign'\n" >"$foreign/$foreign_key"
GSETTINGS_MOCK_STATE="$foreign" GSETTINGS_MOCK_LOG="$tmp/gsettings-foreign.log" \
  PATH="$stubdir:$PATH" PREFIX="$tmp/prefix" XDG_CONFIG_HOME="$tmp/config" ./uninstall.sh

grep -q "read-selection-tts/" "$foreign/custom-keybindings"
test -f "$foreign/$foreign_key"

test ! -e "$tmp/prefix/bin/read-selection-tts"



run_ipc_case() {
  helper="$1"
  expected="$2"
  ipc_runtime="$tmp/ipc-${helper}"
  ipc_sock="$ipc_runtime/mpv.sock"
  ipc_received="$tmp/${helper}.ipc"
  mkdir -p "$ipc_runtime"
  python3 - "$ipc_sock" "$ipc_received" <<'PYIPC' &
import os
import socket
import sys

sock_path, out_path = sys.argv[1:3]
try:
    os.unlink(sock_path)
except FileNotFoundError:
    pass
with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as server:
    server.bind(sock_path)
    server.listen(1)
    conn, _ = server.accept()
    with conn:
        data = conn.recv(4096)
    with open(out_path, 'wb') as out:
        out.write(data)
PYIPC
  server_pid="$!"
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    [ -S "$ipc_sock" ] && break
    sleep 0.1
  done
  READ_SELECTION_TTS_RUNTIME_DIR="$ipc_runtime" READ_SELECTION_TTS_SOCKET="$ipc_sock" "bin/${helper}-read-selection-tts"
  wait "$server_pid"
  grep -q "$expected" "$ipc_received"
}

run_ipc_case pause '"pause",true'
run_ipc_case continue '"pause",false'

cat >"$stubdir/wl-paste" <<'STUB'
#!/usr/bin/env bash
printf 'private selected text\n'
STUB
chmod +x "$stubdir/wl-paste"

cat >"$stubdir/edge-tts" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${EDGE_TTS_MOCK_LOG:?}"
file=""
out=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --text) echo "--text must not be used" >&2; exit 9 ;;
    --file) file="$2"; shift 2 ;;
    --write-media) out="$2"; shift 2 ;;
    *) shift ;;
  esac
done
test -s "$file"
printf 'audio from %s\n' "$file" >"$out"
STUB
chmod +x "$stubdir/edge-tts"

cat >"$stubdir/mpv" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${MPV_MOCK_LOG:?}"
sleep 0.1
STUB
chmod +x "$stubdir/mpv"

runtime="$tmp/runtime"
mkdir -p "$runtime"
EDGE_TTS_MOCK_LOG="$tmp/edge.log" MPV_MOCK_LOG="$tmp/mpv.log" \
  PATH="$stubdir:$PATH" XDG_RUNTIME_DIR="$runtime" XDG_CONFIG_HOME="$tmp/config" \
  bin/read-selection-tts

test "$(stat -c %a "$runtime/read-selection-tts")" = "700"
test -f "$runtime/read-selection-tts/read-selection.mp3"
test ! -e "$runtime/read-selection-tts/mpv.pid"
test ! -e "$runtime/read-selection-tts/mpv.sock"
if ls "$runtime/read-selection-tts"/read-selection.*.txt >/dev/null 2>&1; then
  echo "selection temp file was not cleaned up" >&2
  exit 1
fi
grep -q -- "--file" "$tmp/edge.log"
if grep -q "private selected text" "$tmp/edge.log"; then
  echo "selected text leaked into edge-tts argv log" >&2
  exit 1
fi

cat >"$stubdir/wl-paste" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
chmod +x "$stubdir/wl-paste"
: >"$tmp/edge-empty.log"
mkdir -p "$tmp/empty-runtime"
EDGE_TTS_MOCK_LOG="$tmp/edge-empty.log" MPV_MOCK_LOG="$tmp/mpv-empty.log" \
  PATH="$stubdir:$PATH" XDG_RUNTIME_DIR="$tmp/empty-runtime" XDG_CONFIG_HOME="$tmp/config" \
  bin/read-selection-tts
if [ -s "$tmp/edge-empty.log" ]; then
  echo "edge-tts should not run for an empty selection" >&2
  exit 1
fi



cat >"$stubdir/wl-paste" <<'STUB'
#!/usr/bin/env bash
echo "wl-paste should not run in --stdin mode" >&2
exit 22
STUB
chmod +x "$stubdir/wl-paste"
cat >"$stubdir/edge-tts" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
file=""
out=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --text) echo "--text must not be used" >&2; exit 9 ;;
    --file) file="$2"; shift 2 ;;
    --write-media) out="$2"; shift 2 ;;
    *) shift ;;
  esac
done
grep -q 'stdin text for agent' "$file"
printf 'audio\n' >"$out"
printf '%s\n' "$*" >>"${STDIN_EDGE_LOG:?}"
STUB
chmod +x "$stubdir/edge-tts"
cat >"$stubdir/mpv" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
chmod +x "$stubdir/mpv"
stdin_runtime="$tmp/stdin-runtime"
mkdir -p "$stdin_runtime"
printf 'stdin text for agent\n' | STDIN_EDGE_LOG="$tmp/stdin-edge.log" PATH="$stubdir:$PATH" XDG_RUNTIME_DIR="$stdin_runtime" XDG_CONFIG_HOME="$tmp/config" bin/read-selection-tts --stdin
test -f "$stdin_runtime/read-selection-tts/read-selection.mp3"

cat >"$stubdir/wl-paste" <<'STUB'
#!/usr/bin/env bash
printf 'text for failing player\n'
STUB
chmod +x "$stubdir/wl-paste"
cat >"$stubdir/edge-tts" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
out=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --write-media) out="$2"; shift 2 ;;
    *) shift ;;
  esac
done
printf 'audio\n' >"$out"
STUB
chmod +x "$stubdir/edge-tts"
cat >"$stubdir/mpv" <<'STUB'
#!/usr/bin/env bash
exit 42
STUB
chmod +x "$stubdir/mpv"
fail_runtime="$tmp/fail-runtime"
mkdir -p "$fail_runtime"
set +e
PATH="$stubdir:$PATH" XDG_RUNTIME_DIR="$fail_runtime" XDG_CONFIG_HOME="$tmp/config" bin/read-selection-tts
fail_status="$?"
set -e
test "$fail_status" = "42"
test ! -e "$fail_runtime/read-selection-tts/mpv.pid"
test ! -e "$fail_runtime/read-selection-tts/mpv.sock"

cat >"$stubdir/kill" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${KILL_MOCK_LOG:?}"
exit 0
STUB
chmod +x "$stubdir/kill"
unsafe_runtime="$tmp/unsafe-runtime"
mkdir -p "$unsafe_runtime/read-selection-tts"
printf 'not-a-pid\n' >"$unsafe_runtime/read-selection-tts/mpv.pid"
KILL_MOCK_LOG="$tmp/kill.log" PATH="$stubdir:$PATH" PREFIX="$tmp/no-such-prefix" \
  READ_SELECTION_TTS_RUNTIME_DIR="$unsafe_runtime/read-selection-tts" XDG_CONFIG_HOME="$tmp/unsafe-config" ./uninstall.sh
test ! -s "$tmp/kill.log"


cat >"$stubdir/wl-paste" <<'STUB'
#!/usr/bin/env bash
printf 'voice fallback text\n'
STUB
chmod +x "$stubdir/wl-paste"
cat >"$stubdir/edge-tts" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
voice=""
out=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --voice) voice="$2"; shift 2 ;;
    --write-media) out="$2"; shift 2 ;;
    *) shift ;;
  esac
done
printf '%s\n' "$voice" >"${VOICE_MOCK_LOG:?}"
printf 'audio\n' >"$out"
STUB
chmod +x "$stubdir/edge-tts"
cat >"$stubdir/mpv" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
chmod +x "$stubdir/mpv"
invalid_config="$tmp/invalid-config/read-selection-tts"
mkdir -p "$invalid_config" "$tmp/invalid-runtime"
printf 'READ_SELECTION_TTS_VOICE=bad;touch-owned\n' >"$invalid_config/config"
VOICE_MOCK_LOG="$tmp/voice.log" PATH="$stubdir:$PATH" XDG_RUNTIME_DIR="$tmp/invalid-runtime" XDG_CONFIG_HOME="$tmp/invalid-config" bin/read-selection-tts
grep -q '^en-US-AriaNeural$' "$tmp/voice.log"

unsafe_parent="$tmp/unsafe-parent"
mkdir -p "$unsafe_parent" "$tmp/symlink-target"
ln -s "$tmp/symlink-target" "$unsafe_parent/read-selection-tts"
set +e
PATH="$stubdir:$PATH" XDG_RUNTIME_DIR="$unsafe_parent" XDG_CONFIG_HOME="$tmp/config" bin/read-selection-tts >/"$tmp/unsafe.out" 2>"$tmp/unsafe.err"
unsafe_status="$?"
set -e
test "$unsafe_status" != "0"
grep -q "unsafe runtime directory" "$tmp/unsafe.err"

cp /bin/sleep "$stubdir/mpv"
chmod +x "$stubdir/mpv"
PATH="$stubdir:$PATH" mpv 30 &
stop_target="$!"
stop_runtime="$tmp/stop-runtime/read-selection-tts"
mkdir -p "$stop_runtime"
printf '%s\n' "$stop_target" >"$stop_runtime/mpv.pid"
: >"$stop_runtime/mpv.sock"
READ_SELECTION_TTS_RUNTIME_DIR="$stop_runtime" PATH="$stubdir:$PATH" bin/stop-read-selection-tts
for _ in 1 2 3 4 5 6 7 8 9 10; do
  kill -0 "$stop_target" 2>/dev/null || break
  sleep 0.1
done
if kill -0 "$stop_target" 2>/dev/null; then
  echo "stop helper did not terminate mpv stub" >&2
  kill "$stop_target" 2>/dev/null || true
  exit 1
fi
test ! -e "$stop_runtime/mpv.pid"
test ! -e "$stop_runtime/mpv.sock"

rotate_runtime="$tmp/rotate-runtime"
mkdir -p "$rotate_runtime/read-selection-tts"
printf '0123456789\n' >"$rotate_runtime/read-selection-tts/read-selection-tts.log"
READ_SELECTION_TTS_LOG_MAX_BYTES=1 PATH="$stubdir:$PATH" XDG_RUNTIME_DIR="$rotate_runtime" XDG_CONFIG_HOME="$tmp/config" bin/stop-read-selection-tts
test -f "$rotate_runtime/read-selection-tts/read-selection-tts.log.old"

echo "smoke tests passed"
