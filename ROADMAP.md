# Roadmap

This document outlines planned features and enhancements for `read-selection-tts`.

---

## 1. Interactive Demo (Media)
* Create a short 5-10 second demonstration GIF or video showing the helper in action.
* Embed the GIF in the `README.md` to give first-time visitors a visual layout of the tool's execution.

## 2. Multi-Language / Language Auto-Detection
Currently, the application is limited to a single hardcoded voice. Reading foreign text results in a heavy accent or translation failure.

### Proposed Architecture
* **Configurable Language Map:** Allow users to map ISO 2-letter language codes to specific voices in `~/.config/read-selection-tts/config`:
  ```bash
  READ_SELECTION_TTS_VOICE_EN="en-US-AriaNeural"
  READ_SELECTION_TTS_VOICE_ES="es-ES-ElviraNeural"
  READ_SELECTION_TTS_VOICE_DE="de-DE-KatjaNeural"
  ```
* **Zero-Dependency Language Detector:** Integrate a lightweight language detection step inside the Python helper (using character unicode block checking) or standard tools, detecting language code (e.g. `es`) and reading it using the configured voice for that language.

## 3. Streaming/Pipelined Playback
* Currently, the script blocks until `edge-tts` has written the entire selection's audio to disk before playing it with `mpv`.
* Explore piping the stdout stream from `edge-tts` directly into `mpv` (or buffering chunks) so that playback starts instantly, even on extremely long selections (e.g., full-page articles).

## 4. Clipboard Mode (`--clipboard`)
* Add a `--clipboard` flag to read from the `Ctrl+C` clipboard via `wl-paste --clipboard` instead of the primary selection.
* This would complement the existing `--stdin` and default primary-selection modes.
* Useful for reading text copied from PDFs or applications that don't support mouse-primary selection on Wayland.

## 5. Prefer IPC `quit` Before PID Kill in Stop Logic
* `stop-read-selection-tts` currently sends `SIGTERM`/`SIGKILL` to the mpv process by PID.
* A cleaner approach: send `{"command":["quit"]}` to the mpv IPC socket first, then fall back to PID-based kill if the socket is absent or the command fails.
* This avoids the (unlikely) risk of killing a recycled PID and lets mpv shut down cleanly.

## 6. Shortcut Conflict Documentation
* Document known shortcut conflicts in README or `docs/`.
* `Ctrl+Alt+C` (continue) conflicts with some terminal emulators and applications.
* `Ctrl+Alt+S` (pause) may conflict in certain desktop configurations.
* Note that all bindings are overridable via `READ_SELECTION_TTS_*_BINDING` environment variables.

## 7. Bats-Based Integration Tests
* Replace the hand-rolled `tests/smoke.sh` with [Bats](https://github.com/bats-core/bats-core) for better test isolation, readable output, and per-test teardown.
* Priority test cases to add:
  - `pause`/`continue` on an active socket
  - `pause`/`continue` when no socket exists (silent no-op)
  - `stop` with no pidfile (silent no-op)
  - Concurrent `read-selection-tts` invocations (second press stops first)
  - `edge-tts` failure leaves existing playback unchanged
