# Comparison

This project is intentionally small. It is not a replacement for Linux
accessibility tools.

## Orca

Orca is a full screen reader. It reads focused UI, menus, controls, and
application content through the desktop accessibility stack. Use Orca when you
need full keyboard-driven screen-reader behavior.

Use `read-selection-tts` when you only want to select a passage and hear it in a
natural voice.

## Browser Read Aloud Extensions

Browser extensions often have excellent voices and reading controls, but they
are browser-scoped. They do not help much with terminal output or arbitrary
GNOME selected text.

## Voluble / VoxFree / Piper / Mimic3

These are better directions when privacy/offline operation matters. This project
chooses `edge-tts` because voice quality and setup speed are excellent, at the
cost of sending selected text to an online service.
