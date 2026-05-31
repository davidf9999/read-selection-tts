# Contributing to read-selection-tts

Thank you for your interest in contributing! This is a small, lightweight utility, and we welcome contributions that keep it clean, secure, and minimal.

---

## How to Help

### 1. Reporting Bugs 🐛
If you encounter issues (e.g., keyboard shortcuts not firing, audio failing to play):
1. Check if the dependencies are installed:
   ```bash
   wl-paste --primary
   edge-tts --list-voices
   mpv --version
   ```
2. Check the logs:
   ```bash
   cat "${XDG_RUNTIME_DIR:-/tmp}/read-selection-tts/read-selection-tts.log"
   ```
3. Open an issue on GitHub describing your desktop environment (e.g., Ubuntu 24.04 GNOME Wayland) and paste the relevant log errors.

### 2. Suggesting Enhancements 💡
Please open an issue first to discuss any major feature requests or additions. We want to keep the repository scope narrow and focused on the selected-text workflow.

### 3. Submitting Pull Requests (PRs) 🚀
1. Fork the repository and create your branch.
2. Ensure your changes do not introduce security risks (e.g., do not pass user selection text as command-line arguments to processes).
3. Test your changes locally by running the smoke test suite:
   ```bash
   ./tests/smoke.sh
   ```
4. Submit your pull request with a clear description of the problem solved or feature added.

---

## Coding Guidelines

* **Shell Script Quality:** Avoid bash-isms when not using a `#!/usr/bin/env bash` header, or use standard syntax checked by `bash -n`. Keep code portable.
* **Security First:** Do not write fixed-name temp files directly to shared `/tmp` paths; use `$runtime_base` directories with appropriate permissions (`chmod 700`).
