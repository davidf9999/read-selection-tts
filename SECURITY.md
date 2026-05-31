# Security and Privacy

This project sends selected text to Microsoft's online speech service through `edge-tts`. Do not use it for secrets, credentials, private documents, or sensitive personal information.

The helper scripts create temporary files and sockets under `/tmp`:

- `/tmp/read-selection-tts.mp3`
- `/tmp/read-selection-tts-mpv.sock`
- `/tmp/read-selection-tts.log`

Report security concerns privately while the repository is private.
