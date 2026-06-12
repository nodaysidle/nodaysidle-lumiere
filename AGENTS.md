# AGENTS.md — Lumiere

## Project

Lumiere is a native macOS 15+ screenshot polish and annotation app.

It watches the clipboard for images, displays them in a polished dark/Volt UI, applies local image processing, supports annotations, and exports PNG/JPEG/HEIC.

## Stack

- macOS 15.0+
- Swift 6
- SwiftUI for app UI
- AppKit where native macOS behavior is required (`NSPanel`, pasteboard, save panel)
- Combine for event streams
- SwiftData for local settings
- Core Image / Vision / Core ML framework APIs for local processing
- Xcode project: `Lumiere.xcodeproj`
- XcodeGen source: `project.yml`

## Hard Rules

- Native macOS only.
- No network/cloud dependencies.
- No backend/server components.
- No cross-platform framework rewrite.
- No third-party ML model dependency.
- Keep all processing local.
- Use NODAYSIDLE dark UI with Volt accent `#C8FF00`.
- Do not add features beyond the requested scope.
- Do not build, install, launch, sign, notarize, or package unless explicitly approved.

## Entry Points

- App entry: `Lumiere/LumiereApp.swift`
- Root view: `Lumiere/ContentView.swift`
- Main view model: `Lumiere/Core/MainViewModel.swift`
- Floating panel: `Lumiere/Features/UI/Services/PanelManager.swift`
- Image display/editor: `Lumiere/Features/UI/Views/ImageDisplayView.swift`

## Core Services

- Clipboard: `Lumiere/Core/Services/ClipboardMonitorService.swift`
- Processing: `Lumiere/Core/Services/ImageProcessingPipeline.swift`
- Inference wrapper: `Lumiere/Core/Services/CoreMLInferenceService.swift`
- Annotation rendering: `Lumiere/Core/Services/AnnotationRenderingService.swift`
- Settings: `Lumiere/Core/Services/SettingsStore.swift`

## Build Commands

Do not run without NDI approval.

Debug build:

```bash
xcodebuild -project Lumiere.xcodeproj -scheme Lumiere -configuration Debug -derivedDataPath build/DerivedData clean build
```

Install locally after approved successful build:

```bash
ditto build/DerivedData/Build/Products/Debug/Lumiere.app /Applications/Lumiere.app
```

## Current Known Gaps

- Core ML layer currently uses heuristic pixel metrics unless real `.mlmodel` assets are added.
- Release signing/notarization/DMG flow is not defined yet.
- Clipboard monitoring restart behavior needs verification/fix before shipping.
- Annotation preview/export coordinate alignment needs visual smoke verification before shipping.

## Verification Gates

For buildability work:

1. Inspect git status and project rules.
2. Make the smallest source/project-file change.
3. Verify stale/missing references are gone by searching files.
4. Run build only after explicit approval.

For ship work:

1. Debug build passes.
2. App launches locally.
3. Clipboard image import works.
4. Shadow/perspective controls do not crash.
5. Annotation preview works.
6. Exported image opens and annotations align.
7. Release package/checksum/notarization path is documented.
