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
