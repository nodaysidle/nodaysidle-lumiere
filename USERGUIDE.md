# Lumiere — User Guide

> Native macOS screenshot polish & annotation. Dark. Local. No network.

## Install

```bash
# After approved Release build:
ditto build/InternalReleaseDerivedData/Build/Products/Release/Lumiere.app /Applications/Lumiere.app
open /Applications/Lumiere.app
```

macOS may show a Gatekeeper warning for unsigned internal builds. Right-click → Open to bypass.

## Quick Start

1. **Capture an image** — Take a screenshot (⇧⌘5 or ⇧⌘4), or copy any image to clipboard. Lumiere auto-detects clipboard images.
2. **Paste manually** — ⌘V or File → "Capture from Clipboard" (⇧⌘S) if auto-capture is off.
3. **Polish** — Use the floating toolbar or the bottom action bar:
   - ☀ **Shadow** — Applies directional shadow styling with depth
   - ◻ **Perspective** — Auto-detects document edges and corrects perspective
4. **Annotate** — Click "Annotate" or ⌥⌘A to enter annotation mode:
   - **Arrow** (⌥⌘A) — Draw directional arrows
   - **Rectangle** (⌥⌘R) — Draw outlined/filled rectangles
   - **Text** (⌥⌘T) — Place text labels
   - **Callout** (⌥⌘C) — Place callout bubbles with tails
   - **Blur** (⌥⌘B) — Blur regions (applied at export)
   - **Undo** — ⌘Z to remove last annotation
5. **Export** — ⌘E opens save dialog. Pick PNG (lossless), JPEG (smaller), or HEIC format.

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⇧⌘S | Capture from clipboard |
| ⌘E | Export image |
| ⌘Z | Undo last annotation |
| ⌥⌘A | Arrow annotation tool |
| ⌥⌘T | Text annotation tool |
| ⌥⌘R | Rectangle annotation tool |
| ⌥⌘B | Blur annotation tool |
| ⌘, | Settings |

## Floating Toolbar

A floating glass panel appears at the bottom-center of your screen. Move your cursor near it to reveal it; move away to hide. You can drag it to reposition — it remembers where you left it.

## Window Tiling (Aerospace / yabai)

Lumiere supports tiling window managers. Minimum window size: 720×520px (fits quarter-tile on 1440px screens). The floating toolbar stays on the active monitor and won't be tiled.

If the toolbar appears on the wrong screen after a monitor change, quit and relaunch Lumiere.

## Settings

⌘, opens settings:
- **Auto-capture** — Automatically import clipboard images (on by default)
- **Default export format** — PNG (lossless), JPEG, or HEIC
- **Tool presets** — Save and switch between annotation defaults

## Notes

- All processing is local. No network calls. No cloud upload.
- Images stay on your machine. Annotations are rendered in-memory.
- Export uses your source image resolution — window size doesn't affect output quality.
- For unsigned internal builds, macOS may block on first launch. Right-click → Open to trust.
