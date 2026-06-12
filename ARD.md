# Architecture Requirements Document

## 🧱 System Overview
Lumiere is a native macOS application providing AI-assisted image polish and annotation through a floating glass interface. The app uses Core ML models optimized for Apple Neural Engine to deliver one-click enhancements like shadow matching and perspective correction. A 'Liquid Glass' UI remains unobtrusive until cursor proximity activation, with clipboard monitoring for automatic screenshot capture.

## 🏗 Architecture Style
Native macOS app using SwiftUI for declarative UI with AppKit bridging for system-level integration. Event-driven architecture using Combine for reactive data flows. Single-process application with Core ML model loading on-demand. Local-first with no network dependencies.

## 🎨 Frontend Architecture
- **Framework:** SwiftUI with .ultraThinMaterial glassmorphism, matchedGeometryEffect for smooth UI transitions
- **Color Palette (MANDATORY):** Volt accent `#C8FF00`, background `#0A0A0F`, surface/cards `#14141F`, text primary `#F0F0F5`, text secondary `#6B6B80`, error `#FF3B5C`, success `#00E676`. ALL views must use these exact colors via Color extension in Color+Palette.swift
- **State Management:** Combine publishers with @Observable and @StateObject for reactive state propagation
- **Routing:** Single-view app with overlay-based panels, no navigation stack required
- **Build Tooling:** Xcode project with Swift Package Manager for dependencies

## 🧠 Backend Architecture
- **Approach:** Monolithic Swift app with AppKit integration for system-level hooks (pasteboard, screen capture)
- **API Style:** Internal Swift protocols with Combine publishers, no external APIs
- **Services:**
- ClipboardMonitorService - NSPasteboard polling for screenshot detection
- CoreMLInferenceService - On-demand model loading and execution
- ImageProcessingPipeline - Combines Core ML output with CIFilter effects
- AnnotationRenderingService - Vector-based annotation layer composition

## 🗄 Data Layer
- **Primary Store:** SwiftData for user preferences, tool presets, and recent files
- **Relationships:** Single-entity schema with UserSettings containing preset collections
- **Migrations:** Lightweight SwiftData automatic migrations for settings schema evolution

## ☁️ Infrastructure
- **Hosting:** Local macOS application bundled via Xcode, distributed outside App Store initially
- **Scaling Strategy:** Single-user desktop app, optimization focuses on memory efficiency and model loading latency
- **CI/CD:** Xcode Cloud or GitHub Actions for macOS runners running swift test and xcodebuild

## ⚖️ Key Trade-offs
- macOS exclusivity enables deep system integration but limits platform reach
- On-device Core ML ensures privacy and latency but requires Apple Silicon hardware
- UltraThinMaterial provides premium aesthetic at cost of reduced UI clarity on some backgrounds
- Combine adds learning curve but provides consistent reactive patterns across SwiftUI and AppKit
- SwiftData simplifies persistence but requires macOS 14+ minimum deployment target

## 📐 Non-Functional Requirements
- Sub-second processing for all Core ML inference operations
- Memory footprint under 200MB with efficient model loading/unloading
- UI responsiveness maintained during heavy image processing via background queues
- Adheres to macOS dark mode and accessibility guidelines (VoiceOver, Dynamic Type)
- Graceful degradation on pre-M1 hardware with fallback to CPU inference