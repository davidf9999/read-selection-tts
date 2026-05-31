# Security and Privacy

This project sends selected text to Microsoft's online speech service through `edge-tts`. Do not use it for secrets, credentials, private documents, or sensitive personal information.

Runtime files are stored under `${XDG_RUNTIME_DIR:-/tmp}/read-selection-tts`, and the scripts create that directory with mode `0700` before writing the generated MP3, `mpv` IPC socket, PID file, and log. The fallback under `/tmp` is still per-user-private by directory permissions, not a fixed shared file path.

The installer writes persistent local configuration to `~/.config/read-selection-tts/config` with mode `0600`.

Report security concerns privately while the repository is private.
