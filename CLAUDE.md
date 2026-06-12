# CLAUDE.md — Lumiere

## Project

Lumiere is a native macOS 15+ screenshot polish and annotation app.

## Primary Rules

Use `AGENTS.md` as the repo law for current agent behavior, build commands, verification gates, and hard constraints.

## Stack

- Swift 6
- SwiftUI with polished glass styling
- AppKit for native macOS panel/window behavior
- Combine for clipboard and processing events
- SwiftData for local settings persistence
- Core Image / Vision / Core ML framework APIs for local processing

## Do Not

- Do not add network dependencies or server components.
- Do not use cross-platform frameworks.
- Do not create backend services.
- Do not introduce alternate UI frameworks.
- Do not add third-party model downloads.
- Do not ship generated build artifacts in source.

## Build

```bash
xcodebuild -project Lumiere.xcodeproj -scheme Lumiere -configuration Debug -derivedDataPath build/DerivedData clean build
```
