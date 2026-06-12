import AppKit
import Combine
import ImageIO
import UniformTypeIdentifiers

@MainActor
final class MainViewModel: ObservableObject {
    @Published var currentImage: NSImage?
    @Published var annotations: [Annotation] = []
    @Published var isProcessing = false
    @Published var isExporting = false
    @Published var statusMessage: String?
    @Published var isAnnotateMode = false
    @Published var activeTool: AnnotationTool = .arrow
    @Published var imageVersion = UUID()

    private let clipboardMonitor = ClipboardMonitorService()
    private let processingPipeline = ImageProcessingPipeline()
    private let annotationService = AnnotationRenderingService()
    private let settingsStore: SettingsStore
    private let logger = LumiereLogger.ui
    private var cancellables = Set<AnyCancellable>()
    private var statusClearWorkItem: DispatchWorkItem?

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        setupBindings()
        applyCurrentPresetDefaults()
        updateMonitoringState()
    }

    func ingestImage(_ image: NSImage, sourceLabel: String) {
        currentImage = image
        annotations.removeAll()
        imageVersion = UUID()
        showStatus("Imported from \(sourceLabel)")
    }

    func processShadow() {
        guard let currentImage else { return }
        isProcessing = true
        showStatus("Matching shadow")

        let preset = settingsStore.settings.toolPresets.first
        let params = ShadowParams(
            intensity: preset?.shadowIntensity ?? 0.55,
            blurRadius: 24
        )

        Task {
            do {
                let result = try await processingPipeline.processShadow(image: currentImage, params: params)
                self.currentImage = result.image
                self.imageVersion = UUID()
                self.showStatus("Shadow applied")
            } catch {
                logger.error("Shadow processing failed: \(error.localizedDescription)")
                self.showStatus("Shadow processing failed")
            }
            self.isProcessing = false
        }
    }

    func processPerspective() {
        guard let currentImage else { return }
        isProcessing = true
        showStatus("Correcting perspective")

        Task {
            do {
                let corners = try await processingPipeline.detectCorners(image: currentImage)
                let result = try await processingPipeline.correctPerspective(image: currentImage, corners: corners)
                self.currentImage = result.image
                self.imageVersion = UUID()
                self.isProcessing = false
                self.showStatus("Perspective corrected")
            } catch {
                logger.error("Perspective correction failed: \(error.localizedDescription)")
                self.isProcessing = false
                self.showStatus("No rectangle detected")
            }
        }
    }

    func toggleAnnotationMode() {
        guard currentImage != nil else { return }
        isAnnotateMode.toggle()
        if isAnnotateMode {
            applyCurrentPresetDefaults()
        }
        showStatus(isAnnotateMode ? "Annotation enabled" : "Annotation hidden")
    }

    func selectAnnotationTool(_ tool: AnnotationTool) {
        activeTool = tool
        isAnnotateMode = true
    }

    func undoLastAnnotation() {
        guard !annotations.isEmpty else { return }
        annotations.removeLast()
        showStatus("Removed last annotation")
    }

    func copyToClipboard() {
        guard let image = compositedImage() else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
        showStatus("Copied to clipboard")
    }

    func clearImage() {
        currentImage = nil
        annotations.removeAll()
        imageVersion = UUID()
        isAnnotateMode = false
        showStatus("Image cleared")
    }

    func exportImage() {
        guard compositedImage() != nil else { return }

        let defaultFormat = settingsStore.settings.defaultExportFormat
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = ExportFormat.allCases.map(contentType(for:))
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = "Lumiere-\(Int(Date().timeIntervalSince1970)).\(defaultFormat.rawValue)"

        savePanel.begin { [weak self] response in
            guard response == .OK, let url = savePanel.url else { return }
            self?.saveRenderedImage(to: url)
        }
    }

    private func setupBindings() {
        clipboardMonitor.imagePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] event in
                self?.handleCapture(event)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .lumiereApplyShadow)
            .sink { [weak self] _ in self?.processShadow() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .lumiereApplyPerspective)
            .sink { [weak self] _ in self?.processPerspective() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .lumiereToggleAnnotation)
            .sink { [weak self] _ in self?.toggleAnnotationMode() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .lumiereExportImage)
            .sink { [weak self] _ in self?.exportImage() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .lumiereCopyToClipboard)
            .sink { [weak self] _ in self?.copyToClipboard() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .lumiereClearImage)
            .sink { [weak self] _ in self?.clearImage() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .lumiereUndoAnnotation)
            .sink { [weak self] _ in self?.undoLastAnnotation() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .lumiereUseArrowTool)
            .sink { [weak self] _ in self?.selectAnnotationTool(.arrow) }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .lumiereUseTextTool)
            .sink { [weak self] _ in self?.selectAnnotationTool(.text) }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .lumiereUseRectangleTool)
            .sink { [weak self] _ in self?.selectAnnotationTool(.rectangle) }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .lumiereUseCalloutTool)
            .sink { [weak self] _ in self?.selectAnnotationTool(.callout) }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .lumiereUseBlurTool)
            .sink { [weak self] _ in self?.selectAnnotationTool(.blur) }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .lumiereCaptureClipboard)
            .sink { [weak self] _ in self?.captureFromClipboard() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .lumiereSettingsChanged)
            .sink { [weak self] _ in
                self?.applyCurrentPresetDefaults()
                self?.updateMonitoringState()
            }
            .store(in: &cancellables)
    }

    private func updateMonitoringState() {
        if settingsStore.settings.autoCaptureEnabled {
            clipboardMonitor.startMonitoring()
        } else {
            clipboardMonitor.stopMonitoring()
        }
    }

    private func applyCurrentPresetDefaults() {
        guard let rawTool = settingsStore.settings.toolPresets.first?.annotationDefaults["tool"],
            let tool = AnnotationTool(rawValue: rawTool)
        else {
            activeTool = .arrow
            return
        }

        activeTool = tool
    }

    private func captureFromClipboard() {
        if let event = clipboardMonitor.captureCurrentPasteboardImage() {
            handleCapture(event)
        } else {
            showStatus("No supported clipboard image")
        }
    }

    private func handleCapture(_ event: ImageCaptureEvent) {
        currentImage = event.image
        annotations.removeAll()
        imageVersion = UUID()
        showStatus(event.source == .screenshot ? "Screenshot captured" : "Clipboard image imported")
    }

    private func compositedImage() -> NSImage? {
        guard let currentImage else { return nil }
        guard !annotations.isEmpty else { return currentImage }
        return annotationService.render(annotations: annotations, onto: currentImage)
    }

    private func saveRenderedImage(to url: URL) {
        guard let image = compositedImage() else { return }
        isExporting = true
        showStatus("Exporting image")
        let format = exportFormat(for: url)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let success = Self.write(image: image, to: url, format: format)

            DispatchQueue.main.async {
                self.isExporting = false
                if success {
                    self.settingsStore.addRecentFile(url)
                    self.showStatus("Saved \(url.lastPathComponent)")
                } else {
                    self.showStatus("Export failed")
                }
            }
        }
    }

    nonisolated private static func write(image: NSImage, to url: URL, format: ExportFormat) -> Bool {
        guard let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff) else {
            return false
        }

        let representation: Data?
        switch format {
        case .png:
            representation = bitmap.representation(using: .png, properties: [:])
        case .jpeg:
            representation = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
        case .heic:
            representation = nil
        }

        if format == .heic {
            return writeHEIC(image: image, to: url)
        }

        guard let representation else { return false }

        do {
            try representation.write(to: url)
            return true
        } catch {
            return false
        }
    }

    nonisolated private static func writeHEIC(image: NSImage, to url: URL) -> Bool {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return false
        }

        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.heic.identifier as CFString, 1, nil) else {
            return false
        }

        let properties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.9,
        ]
        CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
        return CGImageDestinationFinalize(destination)
    }

    private func exportFormat(for url: URL) -> ExportFormat {
        ExportFormat(rawValue: url.pathExtension.lowercased()) ?? settingsStore.settings.defaultExportFormat
    }

    private func contentType(for format: ExportFormat) -> UTType {
        switch format {
        case .png:
            return .png
        case .jpeg:
            return .jpeg
        case .heic:
            return .heic
        }
    }

    private func showStatus(_ message: String, duration: TimeInterval = 2.4) {
        statusClearWorkItem?.cancel()
        statusMessage = message

        let workItem = DispatchWorkItem { [weak self] in
            guard self?.statusMessage == message else { return }
            self?.statusMessage = nil
        }
        statusClearWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
    }
}
