# Lumiere

![Lumiere Logo](Lumiere/Resources/Brand/LumiereLogo.svg)

Lumiere is a native macOS 15+ screenshot polish and annotation app for turning clipboard screenshots into clean, exportable visuals. It watches for copied images, applies local image cleanup, provides annotation controls, and exports PNG/JPEG/HEIC without network or backend dependencies.

## Status

- Platform: macOS 15.0+
- Stack: Swift 6, SwiftUI, AppKit, Combine, SwiftData, Core Image/Vision/Core ML framework APIs
- Build: verified locally with Xcode Debug and Release builds
- Tests: Xcode unit-test target included and verified locally
- Distribution: private/internal ad-hoc DMG packaging supported
- Release signing/notarization: not configured yet

## Highlights

- Native dark macOS UI with NODAYSIDLE Volt accent `#C8FF00`
- Floating `NSPanel` toolbar with polished glass styling
- Clipboard image monitoring with duplicate debounce
- Local image processing for shadow styling and perspective correction controls
- Vector annotation tools for arrows, rectangles, text, and callouts
- Export to PNG, JPEG, and HEIC
- Local-only settings persistence

## Requirements

- macOS 15.0+
- Xcode 16+ / Swift 6+

## Project Structure

```text
Lumiere/
  Core/       logging, orchestration, services, theme
  Features/   settings and screenshot UI
  Models/     annotations, image processing, settings models
  Resources/  app icons and brand assets
```

Important files:

- `Lumiere/LumiereApp.swift` — app entry point
- `Lumiere/ContentView.swift` — root view
- `Lumiere/Core/MainViewModel.swift` — workflow orchestration
- `Lumiere/Core/Services/ClipboardMonitorService.swift` — pasteboard image monitoring
- `Lumiere/Core/Services/ImageProcessingPipeline.swift` — image cleanup pipeline
- `Lumiere/Core/Services/CoreMLInferenceService.swift` — local heuristic/Core ML wrapper
- `Lumiere/Core/Services/AnnotationRenderingService.swift` — export rendering
- `Lumiere/Features/UI/Services/PanelManager.swift` — floating panel lifecycle
- `Lumiere/Resources/Assets.xcassets/AppIcon.appiconset/` — bundled app icon assets
- `Lumiere/Resources/Brand/LumiereLogo.svg` — source logo
- `.github/workflows/build.yml` — GitHub Actions test, Release build, and private internal DMG artifact workflow
- `Scripts/package-internal-dmg.sh` — local/CI internal ad-hoc DMG packaging script

## Test Locally

```bash
xcodebuild \
  -project Lumiere.xcodeproj \
  -scheme Lumiere \
  -destination 'platform=macOS' \
  -derivedDataPath build/TestDerivedData \
  test
```

## Build Locally

```bash
xcodebuild \
  -project Lumiere.xcodeproj \
  -scheme Lumiere \
  -configuration Release \
  -derivedDataPath build/InternalReleaseDerivedData \
  clean build
```

Built app path:

```text
build/InternalReleaseDerivedData/Build/Products/Release/Lumiere.app
```

Verify local signature:

```bash
codesign --verify --deep --strict --verbose=2 build/InternalReleaseDerivedData/Build/Products/Release/Lumiere.app
```

## Install Locally

After a successful Release build:

```bash
ditto build/InternalReleaseDerivedData/Build/Products/Release/Lumiere.app /Applications/Lumiere.app
```

## Internal Private DMG

For internal/private testing only, create an unsigned/ad-hoc DMG:

```bash
Scripts/package-internal-dmg.sh
```

Artifacts:

```text
build/Lumiere-Internal-AdHoc.dmg
build/Lumiere-Internal-AdHoc.dmg.sha256
```

The script builds Release, verifies the ad-hoc app signature, verifies bundled icon/logo resources, stages the app with an `/Applications` symlink, creates the DMG, runs `hdiutil verify`, and writes a SHA256 file.

This DMG is not Developer ID signed and not notarized. It is for private/internal testing only and may trigger Gatekeeper friction when copied between machines.

## GitHub Actions

The included workflow runs on `macos-15` and performs:

1. Xcode version printout
2. unit tests
3. Release build
4. ad-hoc signature verification
5. icon/logo resource verification
6. internal unsigned/ad-hoc DMG creation
7. `hdiutil verify`
8. SHA256 generation
9. private GitHub Actions artifact upload

No GitHub Release is created by the workflow.

## Current Known Gaps

- Public release signing/notarization is not configured yet.
- Core ML behavior is currently a local heuristic wrapper unless real `.mlmodel` assets are added later.
- Clipboard-monitor restart behavior has deterministic unit coverage for stop/start publishing.
- Annotation preview/export coordinate semantics have deterministic unit coverage; full interactive visual QA remains a pre-public-release gate.

## Non-Goals

- No backend.
- No cloud processing.
- No telemetry.
- No cross-platform rewrite.
- No third-party model download dependency.
