# Technical Requirements Document

## 🧭 System Context
Lumiere is a native macOS application built with SwiftUI and AppKit, providing AI-assisted image polish and annotation through a floating glass interface. The app runs locally with no network dependencies, using Core ML models optimized for Apple Neural Engine. Single-process architecture with Combine-based reactive data flows.

## 🔌 API Contracts
### ClipboardMonitor
- **Method:** event
- **Path:** internal
- **Auth:** none
- **Request:** NSPasteboard.PasteboardType.image
- **Response:** ImageCaptureEvent(timestamp: Date, image: NSImage, source: ClipboardSource)
- **Errors:**
- PasteboardReadFailure
- InvalidImageType

### CoreMLInference
- **Method:** sync
- **Path:** internal/CoreMLInferenceService
- **Auth:** none
- **Request:** {modelType: ModelType, imageData: CVPixelBuffer}
- **Response:** {predictions: [MLFeatureValue], processingTime: TimeInterval}
- **Errors:**
- ModelLoadFailure
- InferenceTimeout
- InvalidInputFormat

### ShadowMatchingApply
- **Method:** command
- **Path:** internal/ImageProcessingPipeline
- **Auth:** none
- **Request:** {sourceImage: NSImage, shadowParameters: ShadowParams}
- **Response:** {processedImage: NSImage, confidence: Float}
- **Errors:**
- ProcessingFailure
- InsufficientShadowData

### PerspectiveCorrectionApply
- **Method:** command
- **Path:** internal/ImageProcessingPipeline
- **Auth:** none
- **Request:** {sourceImage: NSImage, corners: [CGPoint]}
- **Response:** {correctedImage: NSImage, transformMatrix: CGAffineTransform}
- **Errors:**
- CornerDetectionFailure
- InvalidTransform

### AnnotationRender
- **Method:** command
- **Path:** internal/AnnotationRenderingService
- **Auth:** none
- **Request:** {baseImage: NSImage, annotations: [Annotation]}
- **Response:** NSImage
- **Errors:**
- RenderingFailure
- InvalidAnnotationData

### SettingsPersist
- **Method:** command
- **Path:** internal/SettingsStore
- **Auth:** none
- **Request:** UserSettings
- **Response:** Bool
- **Errors:**
- PersistenceFailure

## 🧱 Modules
### ClipboardMonitorService
- **Responsibilities:**
- Poll NSPasteboard for new images
- Detect screenshot content
- Emit image capture events
- Filter duplicate captures within debounce window
- **Interfaces:**
- startMonitoring()
- stopMonitoring()
- imagePublisher: AnyPublisher<ImageCaptureEvent, Never>
- **Depends on:**
- Combine
- AppKit

### CoreMLInferenceService
- **Responsibilities:**
- Load Core ML models on-demand
- Execute inference on M4 Neural Engine
- Cache model instances in memory
- Handle fallback to CPU inference
- **Interfaces:**
- loadModel(_ type: ModelType) async throws
- infer(_ type: ModelType, image: CVPixelBuffer) async throws -> InferenceResult
- unloadModel(_ type: ModelType)
- **Depends on:**
- Core ML
- Vision

### ImageProcessingPipeline
- **Responsibilities:**
- Apply shadow matching corrections
- Apply perspective transforms
- Compose Core ML output with CIFilter effects
- Manage processing queue with priority
- **Interfaces:**
- processShadow(image: NSImage, params: ShadowParams) async -> ProcessedImage
- correctPerspective(image: NSImage, corners: [CGPoint]) async -> ProcessedImage
- processBatch(_ operations: [ProcessingOperation]) async -> [ProcessedImage]
- **Depends on:**
- CoreMLInferenceService
- CoreImage

### AnnotationRenderingService
- **Responsibilities:**
- Render vector annotations onto images
- Manage annotation layers
- Export compositions with blend modes
- Handle annotation serialization
- **Interfaces:**
- render(annotations: [Annotation], onto: NSImage) -> NSImage
- exportAnnotationData(_ annotations: [Annotation]) -> Data
- createAnnotationLayer() -> AnnotationLayer
- **Depends on:**
- CoreGraphics
- CoreImage

### LiquidGlassUI
- **Responsibilities:**
- Render ultra-thin glass panels
- Handle cursor proximity detection
- Animate panel reveal/hide
- Manage floating window positioning
- **Interfaces:**
- showPanel(at: CGPoint)
- hidePanel()
- updateProximity(cursorLocation: CGPoint)
- setPanelState(_ state: PanelState)
- **Depends on:**
- SwiftUI
- AppKit

### SettingsStore
- **Responsibilities:**
- Persist user preferences via SwiftData
- Manage tool presets
- Track recent files
- Handle schema migrations
- **Interfaces:**
- saveSettings(_ settings: UserSettings)
- loadSettings() -> UserSettings
- savePreset(_ preset: ToolPreset)
- getRecentFiles() -> [URL]
- **Depends on:**
- SwiftData

## 🗃 Data Model Notes
- UserSettings: SwiftData @Model containing themePreference, autoCaptureEnabled, defaultExportFormat, toolPresets array
- ToolPreset: struct with name, shadowIntensity, perspectiveSensitivity, annotationDefaults
- Annotation: enum protocol { case arrow(ArrowAnnotation), case shape(ShapeAnnotation), case text(TextAnnotation), case callout(CalloutAnnotation) }
- ImageCaptureEvent: struct with timestamp, image: NSImage, source: ClipboardSource enum
- InferenceResult: struct with predictions: [MLFeatureValue], confidence: Float, processingTime: TimeInterval
- ShadowParams: struct with direction: CGVector, intensity: Float, blurRadius: CGFloat
- PanelState: enum { case hidden, case revealing(progress: CGFloat), case visible, case dismissing(progress: CGFloat) }

## 🔐 Validation & Security
- Validate image file types on clipboard (restrict to PNG, JPEG, HEIC, TIFF)
- Sanitize annotation paths to prevent rendering exploits
- Sandbox file access scoped to user-selected directories only
- Core ML models bundled within app bundle, no external downloads
- No network permissions required in entitlements
- Code signing for macOS distribution

## 🧯 Error Handling Strategy
Combine-based error propagation with .catch() and .retry() operators. Graceful degradation for Core ML failures (fallback to CPU or skip enhancement). User-facing alerts for critical failures with dismissible option. Error events logged with context for debugging.

## 🔭 Observability
- **Logging:** OSLog with subsystem 'com.lumiere.app' and categories: 'ClipboardMonitor', 'CoreML', 'ImageProcessing', 'Annotation', 'UI'. Different log levels for development vs release builds.
- **Tracing:** Instruments profiling for Core ML performance. Signposts for image processing pipeline stages. User interaction tracing for UI responsiveness analysis.
- **Metrics:**
- Model load time (milliseconds)
- Inference latency per model type
- Memory footprint during processing
- Clipboard poll count per session
- Processing queue depth

## ⚡ Performance Notes
- Core ML models lazy-loaded on first use to reduce launch time
- Image processing on background DispatchQueue.qos(.userInitiated)
- UI updates on @MainActor to maintain responsiveness
- Model memory released after 30 seconds of inactivity
- Clipboard polling interval: 250ms with debounce of 500ms
- Panel proximity detection: 100pt threshold radius

## 🧪 Testing Strategy
### Unit
- ClipboardMonitorService pasteboard reading logic
- CoreMLInferenceService model loading with mock models
- ImageProcessingPipeline transformations with test images
- AnnotationRenderingService layer composition
- SettingsStore SwiftData CRUD operations
### Integration
- End-to-end clipboard capture to display pipeline
- Core ML inference with real models on sample images
- Annotation save/load roundtrip
- Settings persistence across app launches
### E2E
- Screenshot capture workflow from clipboard to edit
- Shadow matching application on sample images
- Perspective correction on document photos
- Export functionality with various formats

## 🚀 Rollout Plan
- Phase 1: Core clipboard monitoring and image display pipeline
- Phase 2: Core ML integration with shadow matching model
- Phase 3: Perspective correction feature
- Phase 4: Annotation system with vector tools
- Phase 5: Liquid Glass UI polish and proximity animations
- Phase 6: Settings persistence and preset management
- Phase 7: Beta distribution outside App Store for feedback
- Phase 8: App Store submission with sandbox entitlements

## ✅ Resolved Decisions
- Shadow detection uses Vision framework built-in VNDetectRectanglesRequest + CIColorControls CIFilter (no custom Core ML model needed — Vision handles detection, CIFilter handles the shadow adjustments)
- Maximum image resolution: 8192×8192 pixels (downscale larger images)
- Keyboard shortcuts: ⌘⇧S capture from clipboard, ⌘E export, ⌘Z undo annotation, ⌘⇧A arrow, ⌘⇧T text, ⌘⇧R rectangle, ⌘⇧B blur
- Default export format: PNG (lossless), with JPEG option for smaller files