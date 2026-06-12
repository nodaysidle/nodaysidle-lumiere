# Agent Prompts — Lumiere

## 🧭 Global Rules

### ✅ Do
- Use SwiftUI for all views with .ultraThinMaterial for glass effects
- Use Combine for async event streams (clipboard, processing events)
- Use SwiftData for settings persistence, no network/cloud
- Target macOS 15.0+ with M4 Neural Engine optimization
- Use AppKit NSPanel for floating windows with level.floating

### ❌ Don’t
- Do not add network dependencies or server components
- Do not use cross-platform frameworks (macOS-only)
- Do not create backend services - all processing local
- Do not introduce alternative UI frameworks (SwiftUI only)
- Do not use third-party ML models - Core ML + Vision only

## 🧩 Task Prompts
## Foundation: Xcode Project Setup with Dark Theme

**Context**
Create macOS Xcode project targeting macOS 15.0+, SwiftData for persistence, OSLog infrastructure, and dark chalk color palette. Single-user local-first, App Store sandboxed.

### Universal Agent Prompt
```
ROLE: Expert macOS SwiftUI Engineer

GOAL: Create Xcode project with macOS app target, SwiftData, OSLog, and dark chalk color palette

CONTEXT: Create macOS Xcode project targeting macOS 15.0+, SwiftData for persistence, OSLog infrastructure, and dark chalk color palette. Single-user local-first, App Store sandboxed.

FILES TO CREATE:
- Lumiere/Core/Logging/Logger.swift
- Lumiere/Core/Theme/Color+Palette.swift
- Lumiere/Models/Settings/UserSettings.swift
- Lumiere/Models/Settings/ToolPreset.swift
- Lumiere.entitlements

FILES TO MODIFY:
_None_

DETAILED STEPS:
1. Create Xcode project with macOS app target, bundle ID com.lumiere.app, deployment target macOS 15.0
2. Configure folder structure: Features/, Core/, Models/, Resources/ in Xcode groups
3. Create Logger.swift with OSLog subsystem 'com.lumiere.app' and category enum (ClipboardMonitor, CoreML, ImageProcessing, Annotation, UI)
4. Create Color+Palette.swift with Volt palette: accent #C8FF00, background #0A0A0F, surface #14141F, textPrimary #F0F0F5, textSecondary #6B6B80, error #FF3B5C, success #00E676. MANDATORY: every view must use Color.Lumiere.accent, Color.Lumiere.background etc — no hardcoded colors anywhere
5. Create UserSettings and ToolPreset SwiftData models with @Model decorator, defaults, and Codable conformance

VALIDATION:
xcodebuild -scheme Lumiere -configuration Debug clean build
```