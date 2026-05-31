# Changelog

## 0.1.1 - 2026-05-31

### Fixed

- `install.sh` never installed `lib/common.sh` to the prefix; all installed
  tools failed immediately on first run with "No such file or directory".
  Users who installed v0.1.0 should run `./uninstall.sh && ./install.sh`.
- `bin/read-selection-tts`: flock subshell started `mpv` as a grandchild
  process, causing `wait` to return 127 immediately and cleanup to remove
  the pidfile and socket while audio was still playing, breaking
  pause/continue/stop for the current session.
- `tests/smoke.sh`: grep checks pointed at `bin/read-selection-tts` for
  strings that had moved to `lib/common.sh`, causing the test suite to fail
  on every run.
- CI: ShellCheck was missing `-x` and `lib/common.sh`; `source=` path
  annotations in bin scripts were CWD-relative rather than script-dir-relative.

### Added

- README: "Optional stop shortcut" and "Primary selection vs clipboard" sections.
- ROADMAP: `--clipboard` mode, IPC-based stop, shortcut conflict docs, Bats tests.

## 0.1.0 - 2026-05-31

- Initial Ubuntu/GNOME/Wayland selected-text read-aloud helper.
- Add read, pause, continue, and stop scripts.
- Add GNOME custom shortcut installer and uninstaller.
- Add smoke tests and documentation.
