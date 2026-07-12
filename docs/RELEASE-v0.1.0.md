# Lumiere v0.1.0

NODAYSIDLE Lumiere first internal macOS release.

Built from `main` at commit `3b7da64`.

## What's in this release

- **Screenshot auto-capture** — clipboard monitoring for screenshots and copied images
- **Vector annotations** — arrow, rectangle, text, callout, and blur tools
- **Shadow styling** — directional shadow depth with intensity/size/opacity controls
- **Perspective correction** — Vision framework auto-detect document edges
- **Floating glass toolbar** — NSPanel with cursor-proximity reveal
- **Export** — PNG (lossless), JPEG, HEIC
- **Fixes** — text annotation input overlay, SettingsStore fallback, Aerospace layout, clipboard monitor restart, CoreML actor metrics for Swift 6

## Install

1. Download `Lumiere-v0.1.0-macos.dmg` from GitHub Releases
2. Open the DMG and drag `Lumiere.app` to `/Applications`
3. **Right-click → Open** on first launch (ad-hoc signed, non-notarized)

Or build from source:

```bash
Scripts/package-internal-dmg.sh
open build/Lumiere-Internal-AdHoc.dmg
```

## Non-notarized notice

This release is **ad-hoc signed and not notarized**. macOS Gatekeeper will block the first launch:

- Right-click (or Ctrl-click) `Lumiere.app` → **Open**
- Click **Open** in the Gatekeeper dialog
- Subsequent launches work normally

For NDI/Kaly internal use and trusted installs only. No Apple Developer ID, no notarization, no App Store.

## Requirements

- macOS 15.0 or later
- Apple Silicon (arm64)

## Known limits

- Core ML pipeline uses heuristic pixel metrics unless real `.mlmodel` assets are added
- No release signing/notarization flow
- Annotation coordinate semantics: unit-tested; full interactive visual QA remains a pre-public-release gate
- DMG is internal/ad-hoc only — no Apple notarization or stapling

## Verify

```bash
# SHA256
shasum -a 256 Lumiere-v0.1.0-macos.dmg
# Expected: 7a029096a6759c9ae972c83f6c829bbb35643cfaa70f9760f81bd1599b18c02b

# DMG verify
hdiutil verify Lumiere-v0.1.0-macos.dmg

# App signature
codesign --verify --deep --strict --verbose=2 /Applications/Lumiere.app

# Tests (repo)
xcodebuild -project Lumiere.xcodeproj -scheme Lumiere -destination 'platform=macOS' -derivedDataPath build/TestDerivedData test
# Expected: 8 tests, 0 failures
```
