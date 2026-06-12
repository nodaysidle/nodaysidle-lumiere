# Tasks Plan — Lumiere

## 📌 Global Assumptions
- Targeting macOS 15.0+ with SwiftUI and AppKit
- M4 Neural Engine available for Core ML optimization
- No network dependencies or server components
- Single-user local-first application
- Xcode 16+ for development
- App Store distribution with sandbox entitlements

## ⚠️ Risks
- Core ML model quality may not match expected results without custom training data
- Clipboard polling at 250ms may impact battery life on portable Macs
- App sandbox may limit file access more than expected during beta testing
- Ultra-thin material performance on older Intel Macs unknown

## 🧩 Epics
## Foundation & Project Setup
**Goal:** Establish the Xcode project structure, macOS app target, and basic SwiftUI app lifecycle

### ✅ Create Xcode project with macOS app target (0.5)

Initialize new Xcode project using SwiftUI for macOS 15+, set bundle identifier, team, and signing settings

**Acceptance Criteria**
- Xcode project builds successfully
- App launches with empty window
- Bundle identifier configured as com.lumiere.app
- Minimum deployment version set to macOS 15.0

**Dependencies**
_None_
### ✅ Configure project structure and folders (0.25)

Create folder structure: Features/, Core/, Models/, Resources/, with proper groups in Xcode

**Acceptance Criteria**
- Folders created in Xcode project navigator
- Each folder maps to physical directory
- GitIgnore excludes Xcode user data and build artifacts

**Dependencies**
- Create Xcode project with macOS app target
### ✅ Set up entitlements and sandbox configuration (0.5)

Configure entitlements file for file access, pasteboard reading, and app sandbox

**Acceptance Criteria**
- Entitlements file added to project
- App sandbox enabled
- File access (user-selected) and pasteboard reading permissions granted
- No network permissions included

**Dependencies**
- Configure project structure and folders
### ✅ Create dark chalk theme color palette (0.25)

Define Color extension with Volt palette: Volt accent `#C8FF00`, background `#0A0A0F`, surface `#14141F`, textPrimary `#F0F0F5`, textSecondary `#6B6B80`, error `#FF3B5C`, success `#00E676`

**Acceptance Criteria**
- Color+Palette.swift created with semantic color names
- Colors MUST use exactly: Volt #C8FF00 (accent), #0A0A0F (background), #14141F (surface), #F0F0F5 (textPrimary), #6B6B80 (textSecondary)
- Colors tested in preview

**Dependencies**
- Configure project structure and folders
### ✅ Set up OSLog logging infrastructure (0.25)

Create logging utility with subsystem 'com.lumiere.app' and category constants

**Acceptance Criteria**
- Logger.swift created with category enum
- Log levels differ between debug and release builds
- All categories: ClipboardMonitor, CoreML, ImageProcessing, Annotation, UI

**Dependencies**
- Configure project structure and folders

## Clipboard Monitoring
**Goal:** Implement background clipboard monitoring to detect new image captures automatically

### ✅ Create ImageCaptureEvent data model (0.25)

Define struct for timestamp, NSImage, and ClipboardSource enum

**Acceptance Criteria**
- ImageCaptureEvent struct conforms to Sendable
- ClipboardSource enum includes cases for screenshot, copy, drag
- Unit tests for model initialization

**Dependencies**
_None_
### ✅ Implement NSPasteboard polling service (1)

Create ClipboardMonitorService using Timer-based polling at 250ms interval

**Acceptance Criteria**
- Service polls NSPasteboard for image types
- Detects PNG, JPEG, HEIC, TIFF formats
- Rejects unsupported formats
- startMonitoring() and stopMonitoring() methods functional

**Dependencies**
- Create ImageCaptureEvent data model
### ✅ Add debounce logic for duplicate prevention (0.5)

Implement 500ms debounce window to filter duplicate pasteboard readings

**Acceptance Criteria**
- Duplicate images within 500ms ignored
- Image hash or changeCount used for comparison
- Unit tests for debounce timing

**Dependencies**
- Implement NSPasteboard polling service
### ✅ Create Combine publisher for image events (0.5)

Expose imagePublisher: AnyPublisher<ImageCaptureEvent, Never> for subscribers

**Acceptance Criteria**
- Publisher emits events on new image detection
- Publisher completes on stopMonitoring()
- Multiple subscribers supported

**Dependencies**
- Add debounce logic for duplicate prevention
### ✅ Add error handling for pasteboard failures (0.5)

Handle PasteboardReadFailure and InvalidImageType errors gracefully

**Acceptance Criteria**
- Errors logged via OSLog
- Service continues running after error
- No crashes on malformed pasteboard data

**Dependencies**
- Implement NSPasteboard polling service

## Core ML Integration
**Goal:** Integrate Core ML models for AI-powered image processing with Apple Neural Engine optimization

### ✅ Define ModelType enum and inference data models (0.25)

Create ModelType enum (shadowDetection, perspectiveCorrection) and InferenceResult struct

**Acceptance Criteria**
- ModelType enum covers all planned models
- InferenceResult includes predictions, confidence, processingTime
- Models conform to Sendable

**Dependencies**
_None_
### ✅ Create CoreMLInferenceService class (1)

Build service for model loading, inference execution, and memory management

**Acceptance Criteria**
- Service loads models on-demand
- Model instances cached in memory
- unloadModel() releases memory

**Dependencies**
- Define ModelType enum and inference data models
### ✅ Implement async inference with CVPixelBuffer input (1)

Create infer() method that accepts CVPixelBuffer and returns InferenceResult

**Acceptance Criteria**
- NSImage converted to CVPixelBuffer for model input
- Inference executes on background queue
- Results include predictions and timing

**Dependencies**
- Create CoreMLInferenceService class
### ✅ Add Neural Engine optimization and CPU fallback (0.5)

Configure model to use M4 Neural Engine with fallback to CPU

**Acceptance Criteria**
- Model configuration specifies compute units
- Fallback to CPU on Neural Engine unavailability
- Configuration logged at model load

**Dependencies**
- Implement async inference with CVPixelBuffer input
### ✅ Implement model memory timeout (0.5)

Release model memory after 30 seconds of inactivity

**Acceptance Criteria**
- Timer tracks last inference time
- Models unloaded after timeout
- Timer resets on new inference

**Dependencies**
- Create CoreMLInferenceService class
### ✅ Create shadow detection Core ML model placeholder (2)

Create or download Vision-compatible model for shadow detection

**Acceptance Criteria**
- Model file added to project bundle
- Model compiles and loads successfully
- Placeholder model generates test predictions

**Dependencies**
- Add Neural Engine optimization and CPU fallback

## Image Processing Pipeline
**Goal:** Build image processing pipeline for shadow matching and perspective correction

### ✅ Create ShadowParams data model (0.25)

Define struct with direction (CGVector), intensity (Float), and blurRadius (CGFloat)

**Acceptance Criteria**
- ShadowParams struct conforms to Codable and Sendable
- Default values provided
- Validation for intensity bounds (0-1)

**Dependencies**
_None_
### ✅ Implement shadow matching processing (1.5)

Create processShadow() method using Core ML output with CIFilter effects

**Acceptance Criteria**
- Method accepts NSImage and ShadowParams
- Returns ProcessedImage with confidence score
- CIFilter chain applies shadow adjustments

**Dependencies**
- Create ShadowParams data model
- Create shadow detection Core ML model placeholder
### ✅ Implement corner detection for perspective (1)

Create corner detection using Vision framework for document edges

**Acceptance Criteria**
- Vision request detects rectangular corners
- Returns array of CGPoint in image coordinates
- Fails gracefully when no corners found

**Dependencies**
_None_
### ✅ Implement perspective correction transform (1.5)

Create correctPerspective() method with corner points and CGAffineTransform

**Acceptance Criteria**
- Method accepts NSImage and corner array
- Applies perspective transform using CoreImage
- Returns ProcessedImage with transform matrix

**Dependencies**
- Implement corner detection for perspective
### ✅ Create priority processing queue (0.5)

Implement DispatchQueue with .userInitiated QoS and operation prioritization

**Acceptance Criteria**
- Queue respects operation priority
- Concurrent processing limited to device capabilities
- Queue depth exposed for observability

**Dependencies**
- Implement shadow matching processing
### ✅ Implement batch processing support (0.5)

Create processBatch() method for multiple operations

**Acceptance Criteria**
- Accepts array of ProcessingOperation
- Returns array of ProcessedImage
- Operations execute based on queue priority

**Dependencies**
- Create priority processing queue

## Annotation System
**Goal:** Build vector-based annotation tools for marking up images

### ✅ Define Annotation enum and subtypes (0.5)

Create Annotation protocol with Arrow, Shape, Text, and Callout cases

**Acceptance Criteria**
- Annotation enum protocol defined
- ArrowAnnotation has start, end, color, thickness
- ShapeAnnotation has type, rect, fill, stroke
- TextAnnotation has content, position, font attributes
- CalloutAnnotation has text, targetPosition, tailPosition

**Dependencies**
_None_
### ✅ Create AnnotationLayer model (0.5)

Define layer container for managing multiple annotations with z-order

**Acceptance Criteria**
- AnnotationLayer holds array of Annotation
- Supports add, remove, reorder operations
- Conforms to Codable for serialization

**Dependencies**
- Define Annotation enum and subtypes
### ✅ Implement annotation rendering service (1.5)

Create render() method using CoreGraphics for vector composition

**Acceptance Criteria**
- Renders annotations onto NSImage
- Supports blend modes and opacity
- Returns composited NSImage

**Dependencies**
- Create AnnotationLayer model
### ✅ Add annotation serialization (0.5)

Implement exportAnnotationData() for saving annotations separately

**Acceptance Criteria**
- Exports Annotation array to JSON/Data
- Import method reconstructs annotations
- Round-trip test passes

**Dependencies**
- Implement annotation rendering service
### ✅ Add path sanitization for security (0.5)

Validate and sanitize annotation paths to prevent rendering exploits

**Acceptance Criteria**
- Path complexity limited
- Invalid paths rejected with error
- Unit tests for malicious path patterns

**Dependencies**
- Implement annotation rendering service

## Liquid Glass UI
**Goal:** Build the floating glass interface with proximity-based reveal animations

### ✅ Create PanelState enum with animation states (0.25)

Define enum with hidden, revealing, visible, and dismissing cases

**Acceptance Criteria**
- PanelState has hidden case
- revealing(progress: CGFloat) case
- visible case
- dismissing(progress: CGFloat) case

**Dependencies**
_None_
### ✅ Create floating glass panel SwiftUI view (1)

Build panel using .ultraThinMaterial with visualEffect and toolbar

**Acceptance Criteria**
- Panel uses .ultraThinMaterial
- Rounded corners with subtle border
- Dark chalk theme colors applied
- View preview renders correctly

**Dependencies**
- Create PanelState enum with animation states
### ✅ Implement cursor proximity detection (1)

Add updateProximity() method with 100pt threshold radius

**Acceptance Criteria**
- Monitors cursor location via NSCGEvent
- Calculates distance to panel edges
- Triggers state changes on threshold crossing

**Dependencies**
- Create floating glass panel SwiftUI view
### ✅ Add panel reveal/hide animations (1)

Animate panel transitions using matchedGeometryEffect and spring

**Acceptance Criteria**
- Smooth reveal animation on proximity
- Smooth hide animation on cursor exit
- Animation duration approximately 0.3 seconds

**Dependencies**
- Implement cursor proximity detection
### ✅ Implement floating window positioning (0.5)

Create NSPanel with level.floating and proper positioning relative to screen

**Acceptance Criteria**
- Panel floats above other windows
- Position stored and restored
- Non-activating panel behavior

**Dependencies**
- Create floating glass panel SwiftUI view
### ✅ Add showPanel and hidePanel methods (0.5)

Expose methods for programmatic panel control

**Acceptance Criteria**
- showPanel(at:) positions and reveals panel
- hidePanel() dismisses panel with animation
- Methods thread-safe with @MainActor

**Dependencies**
- Add panel reveal/hide animations

## Settings Persistence
**Goal:** Implement user settings and preset management using SwiftData

### ✅ Create UserSettings SwiftData model (0.5)

Define @Model with themePreference, autoCaptureEnabled, defaultExportFormat, toolPresets

**Acceptance Criteria**
- @Model decorated class
- Persistent attributes with proper types
- Default values for all properties

**Dependencies**
_None_
### ✅ Create ToolPreset model (0.5)

Define struct with name, shadowIntensity, perspectiveSensitivity, annotationDefaults

**Acceptance Criteria**
- ToolPreset conforms to Codable and Identifiable
- Stored as relationship in UserSettings
- Default presets included

**Dependencies**
- Create UserSettings SwiftData model
### ✅ Implement SettingsStore with SwiftData (1)

Create service for loading and saving UserSettings

**Acceptance Criteria**
- saveSettings() persists to SwiftData
- loadSettings() retrieves or creates defaults
- Settings cached in memory

**Dependencies**
- Create UserSettings SwiftData model
### ✅ Add recent files tracking (0.5)

Implement getRecentFiles() with limit and timestamp management

**Acceptance Criteria**
- Tracks last 10 file URLs
- Removes non-existent files
- Sorted by access time

**Dependencies**
- Implement SettingsStore with SwiftData
### ✅ Create settings UI view (1)

Build SwiftUI settings view with form controls for all settings

**Acceptance Criteria**
- Theme picker (dark chalk only)
- Auto-capture toggle
- Export format picker
- Preset management section

**Dependencies**
- Add recent files tracking
### ✅ Add preset CRUD operations (0.5)

Implement savePreset, deletePreset, and applyPreset methods

**Acceptance Criteria**
- Presets saved to UserSettings
- Delete removes from array
- Apply updates active configuration

**Dependencies**
- Create settings UI view

## Image Display & Editing
**Goal:** Build the main image viewing and editing interface

### ✅ Create image display view (1.5)

Build SwiftUI view for displaying captured images with zoom and pan

**Acceptance Criteria**
- NSImage displayed centered
- Zoom with scroll wheel or pinch gesture
- Pan with drag when zoomed
- Fit-to-screen and actual-size modes

**Dependencies**
_None_
### ✅ Connect clipboard events to image display (0.5)

Subscribe to imagePublisher and update display on new capture

**Acceptance Criteria**
- New images automatically displayed
- Transition animation on image change
- Previous image properly released

**Dependencies**
- Create image display view
- Create Combine publisher for image events
### ✅ Add toolbar with action buttons (1)

Create toolbar for shadow, perspective, annotation, and export actions

**Acceptance Criteria**
- Buttons for each processing action
- Disabled states when no image loaded
- Keyboard shortcuts for common actions

**Dependencies**
- Connect clipboard events to image display
### ✅ Implement export functionality (1)

Add save panel with format selection (PNG, JPEG, HEIC)

**Acceptance Criteria**
- NSSavePanel for file selection
- Format picker with quality settings
- Progress indicator during export

**Dependencies**
- Add toolbar with action buttons

## Observability & Performance
**Goal:** Add logging, metrics, and performance monitoring

### ✅ Add signposts for pipeline stages (0.5)

Instrument Core ML and image processing with os_signpost

**Acceptance Criteria**
- Signposts for model load
- Signposts for inference execution
- Signposts for image transform stages

**Dependencies**
_None_
### ✅ Implement metrics collection (1)

Create Metrics service for tracking model load time, inference latency, memory, queue depth

**Acceptance Criteria**
- Model load time recorded in milliseconds
- Inference latency per model type
- Memory footprint tracked during processing
- Queue depth exposed

**Dependencies**
- Add signposts for pipeline stages
### ✅ Add clipboard poll counter (0.25)

Track poll count per session for analytics

**Acceptance Criteria**
- Counter increments on each poll
- Per-session tracking
- Reset on app launch

**Dependencies**
- Implement metrics collection

## Testing
**Goal:** Build comprehensive test coverage for core functionality

### ✅ Write unit tests for ClipboardMonitorService (1)

Test pasteboard reading, debounce, and event emission

**Acceptance Criteria**
- Mock NSPasteboard for testing
- Debounce timing validated
- Event emission verified

**Dependencies**
- Add error handling for pasteboard failures
### ✅ Write unit tests for CoreMLInferenceService (1)

Test model loading with mocks and error handling

**Acceptance Criteria**
- Mock models for load/unload
- Inference timeout tested
- Memory timeout verified

**Dependencies**
- Implement model memory timeout
### ✅ Write unit tests for ImageProcessingPipeline (1)

Test transformations with sample images

**Acceptance Criteria**
- Shadow processing validated
- Perspective transform verified
- Batch processing tested

**Dependencies**
- Implement batch processing support
### ✅ Write unit tests for AnnotationRenderingService (1)

Test layer composition and serialization

**Acceptance Criteria**
- Render output validated
- Save/load roundtrip passes
- Path sanitization tested

**Dependencies**
- Add path sanitization for security
### ✅ Write unit tests for SettingsStore (0.5)

Test SwiftData CRUD operations in-memory

**Acceptance Criteria**
- Save and load settings
- Preset operations
- Recent files tracking

**Dependencies**
- Add preset CRUD operations
### ✅ Write integration test for clipboard to display (1)

End-to-end test from pasteboard event to UI update

**Acceptance Criteria**
- Clipboard event simulated
- Display update verified
- Memory cleanup confirmed

**Dependencies**
- Write unit tests for ClipboardMonitorService
- Connect clipboard events to image display

## ✅ Resolved Decisions
- Maximum image resolution: 8192×8192 (downscale larger)
- Keyboard shortcuts: ⌘⇧S clipboard capture, ⌘E export, ⌘Z undo, ⌘⇧A arrow, ⌘⇧T text, ⌘⇧R rect, ⌘⇧B blur
- Default export: PNG lossless, JPEG option for size
- Shadow detection: Vision VNDetectRectanglesRequest + CIFilter (no custom model needed)