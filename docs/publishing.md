# Publishing Checklist

Use this before making the repository public.

## GitHub Metadata

Suggested repository topics:

- `text-to-speech`
- `tts`
- `wayland`
- `gnome`
- `linux`
- `accessibility`
- `developer-tools`
- `ai-agent-skill`
- `agent-tool`
- `terminal`

## Demo

Record a short demo showing the actual workflow:

1. Select text in a terminal or document.
2. Press the read shortcut.
3. Pause and continue playback.
4. Optionally show `printf 'hello' | read-selection-tts --stdin` for agent/script usage.

GNOME's built-in screen recorder can capture the visual part. Keep the demo under 10 seconds and avoid selecting private text.

## Announcement Draft

Title idea:

```text
Show HN: A tiny Wayland helper to read selected text aloud using Edge TTS
```

Short positioning:

```text
read-selection-tts is a small GNOME/Wayland helper for reading selected terminal or desktop text aloud with better voice quality than spd-say/eSpeak, without adopting a full screen-reader workflow. It supports keyboard shortcuts and a stdin mode for scripts or agents.
```

Good places to share after the repo is public:

- Hacker News: Show HN
- Reddit: r/linux, r/gnome, r/ubuntu
- GitHub lists that collect Linux accessibility, TTS, or developer tools

Avoid over-positioning it as an accessibility replacement. It is a lightweight selected-text helper, not a screen reader.
