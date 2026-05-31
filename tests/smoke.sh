#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

for file in bin/* install.sh uninstall.sh; do
  bash -n "$file"
done

grep -q "edge-tts" bin/read-selection-tts
grep -q "input-ipc-server" bin/read-selection-tts
grep -q "set_property.*pause.*true" bin/pause-read-selection-tts
grep -q "set_property.*pause.*false" bin/continue-read-selection-tts

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
PREFIX="$tmp/prefix" ./install.sh --no-shortcuts
test -x "$tmp/prefix/bin/read-selection-tts"
test -x "$tmp/prefix/bin/pause-read-selection-tts"
test -x "$tmp/prefix/bin/continue-read-selection-tts"
test -x "$tmp/prefix/bin/stop-read-selection-tts"
PREFIX="$tmp/prefix" ./uninstall.sh
test ! -e "$tmp/prefix/bin/read-selection-tts"

echo "smoke tests passed"
