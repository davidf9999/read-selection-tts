# shellcheck shell=bash
# Shared library for read-selection-tts

load_config() {
  config="${READ_SELECTION_TTS_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/read-selection-tts/config}"
  if [ -r "$config" ]; then
    config_voice="$(awk -F= '$1 == "READ_SELECTION_TTS_VOICE" {print substr($0, index($0, "=") + 1); exit}' "$config" 2>/dev/null || true)"
    config_voice="${config_voice%\"}"
    config_voice="${config_voice#\"}"
    # shellcheck disable=SC2016  # %' strips a trailing single-quote character, not an expression
    config_voice="${config_voice%'}"
    config_voice="${config_voice#'}"
    case "$config_voice" in
      ''|*[!A-Za-z0-9._-]*) ;;
      *) READ_SELECTION_TTS_VOICE="${READ_SELECTION_TTS_VOICE:-$config_voice}" ;;
    esac
  fi
}

default_runtime_base() {
  if [ -n "${READ_SELECTION_TTS_RUNTIME_DIR:-}" ]; then
    printf '%s\n' "$READ_SELECTION_TTS_RUNTIME_DIR"
  elif [ -n "${XDG_RUNTIME_DIR:-}" ]; then
    printf '%s\n' "$XDG_RUNTIME_DIR/read-selection-tts"
  else
    printf '/tmp/read-selection-tts-%s\n' "$(id -u)"
  fi
}

prepare_runtime() {
  # shellcheck disable=SC2154  # runtime_base is set by the sourcing script
  if [ -e "$runtime_base" ] || [ -L "$runtime_base" ]; then
    if [ -L "$runtime_base" ] || [ ! -d "$runtime_base" ] || [ ! -O "$runtime_base" ]; then
      echo "read-selection-tts: unsafe runtime directory: $runtime_base" >&2
      exit 1
    fi
    chmod 700 "$runtime_base"
  else
    mkdir -m 700 "$runtime_base"
  fi
}

trim_log() {
  max_bytes="${READ_SELECTION_TTS_LOG_MAX_BYTES:-1048576}"
  # shellcheck disable=SC2154  # log is set by the sourcing script
  if [ -f "$log" ] && [ "$(wc -c <"$log" 2>/dev/null || echo 0)" -gt "$max_bytes" ]; then
    mv -f "$log" "$log.old" 2>/dev/null || : >"$log"
  fi
}

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "read-selection-tts: $1 is required" >&2
    exit 127
  fi
}

stop_pid() {
  pid="$1"
  [ -n "$pid" ] || return 0
  case "$pid" in *[!0-9]*) return 0 ;; esac
  if [ -r "/proc/$pid/comm" ] && [ "$(cat "/proc/$pid/comm" 2>/dev/null || true)" != "mpv" ]; then
    return 0
  fi
  if kill -0 "$pid" 2>/dev/null; then
    kill -TERM "$pid" 2>/dev/null || true
    for _ in 1 2 3 4 5; do
      kill -0 "$pid" 2>/dev/null || return 0
      sleep 0.1
    done
    kill -KILL "$pid" 2>/dev/null || true
  fi
}
