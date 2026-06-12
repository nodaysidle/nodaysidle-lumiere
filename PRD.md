# Lumiere

## 🎯 Product Vision
A native macOS image polish and annotation tool that leverages M4-optimized Core ML models to deliver instant, AI-assisted studio-quality enhancements through a minimalist floating interface.

## ❓ Problem Statement
Existing image editing tools like Pixelmator Pro and CleanShot X require complex workflows and deep menu navigation for common polish tasks. Users need rapid image enhancement and annotation without leaving their workflow or contending with heavy, always-visible UIs.

## 🎯 Goals
- Deliver one-click AI-powered image enhancements (shadow matching, perspective correction)
- Provide a floating 'Liquid Glass' interface that remains unobtrusive until needed
- Leverage M4 Neural Engine for instant, on-device processing without network dependency
- Enable rapid annotation and polish workflows for screenshots and images
- Maintain a dark, chalk-inspired aesthetic with .ultraThinMaterial glassmorphism

## 🚫 Non-Goals
- Cross-platform support (macOS-exclusive)
- Cloud sync or server-side processing
- Full-featured photo editing (layers, RAW processing, advanced compositing)
- Video editing or screen recording features
- Mobile or tablet versions

## 👥 Target Users
- Designers and product teams requiring quick screenshot annotation
- Content creators needing rapid image polish for social media
- Developers documenting interfaces and workflows
- Marketing professionals preparing visuals without deep Photoshop expertise

## 🧩 Core Features
- One-click shadow matching using Core ML
- Perspective correction via Neural Engine
- Floating glass interface with cursor-proximity activation
- Clipboard monitoring for automatic screenshot capture
- Annotation tools (arrows, text, shapes, blur)
- Quick export to clipboard or file

## ⚙️ Non-Functional Requirements
- Sub-second processing for all AI-enhanced operations
- Low memory footprint with efficient Core ML model loading
- Native macOS feel with AppKit integration
- Local-first architecture with no network dependencies
- Respect system dark mode and accessibility settings

## 📊 Success Metrics
- Time from screenshot capture to annotated export under 10 seconds
- 95% of operations complete in under 1 second on M4 hardware
- User retention through minimal interface friction (fewer clicks than competitors)
- Core ML model inference under 500ms for shadow/perspective operations

## 📌 Assumptions
- Users have M1 or later Apple Silicon for optimal Neural Engine performance
- Users are familiar with macOS conventions and clipboard workflows
- Primary use case is single-image editing, not batch processing
- Images are sourced from screenshots, clipboard, or local files

## ✅ Resolved Decisions
- Support PNG, JPEG, HEIC, TIFF, WebP for input; PNG and JPEG for export
- Keyboard shortcuts: ⌘⇧S capture from clipboard, ⌘E export, ⌘Z undo annotation, ⌘⇧A arrow tool, ⌘⇧T text tool, ⌘⇧R rectangle tool, ⌘⇧B blur tool
- User preferences persist via SwiftData (tool presets, recent files, settings)