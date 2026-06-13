import AppKit
import Combine
import Foundation

final class ClipboardMonitorService {
    enum PasteboardError: LocalizedError {
        case pasteboardReadFailure
        case invalidImageType

        var errorDescription: String? {
            switch self {
            case .pasteboardReadFailure:
                return "Failed to read the pasteboard contents."
            case .invalidImageType:
                return "Pasteboard data did not match a supported image format."
            }
        }
    }

    private let pollInterval: TimeInterval = 0.25
    private let debounceInterval: TimeInterval = 0.5
    private let logger = LumiereLogger.clipboardMonitor
    private let pasteboard = NSPasteboard.general
    private var subject = PassthroughSubject<ImageCaptureEvent, Never>()
    private var timer: Timer?
    private var lastChangeCount = NSPasteboard.general.changeCount
    private var lastCaptureTime = Date.distantPast
    private var lastFingerprint: Int?
    private(set) var isMonitoring = false

    var imagePublisher: AnyPublisher<ImageCaptureEvent, Never> {
        subject.eraseToAnyPublisher()
    }

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        lastChangeCount = pasteboard.changeCount

        let timer = Timer(
            timeInterval: pollInterval,
            target: self,
            selector: #selector(handlePollTimer),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer

        logger.info("Clipboard monitoring started")
    }

    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        timer?.invalidate()
        timer = nil
        logger.info("Clipboard monitoring stopped")
    }

    func captureCurrentPasteboardImage() -> ImageCaptureEvent? {
        readImageFromPasteboard(changeCount: pasteboard.changeCount, isManualCapture: true)
    }

    @objc
    private func handlePollTimer() {
        let changeCount = pasteboard.changeCount
        guard changeCount != lastChangeCount else { return }

        lastChangeCount = changeCount
        guard let event = readImageFromPasteboard(changeCount: changeCount, isManualCapture: false) else {
            return
        }

        subject.send(event)
    }

    private func readImageFromPasteboard(changeCount: Int, isManualCapture: Bool) -> ImageCaptureEvent? {
        do {
            let now = Date()
            if !isManualCapture, now.timeIntervalSince(lastCaptureTime) < debounceInterval {
                return nil
            }

            if let fileEvent = try readImageFromFileURL(now: now) {
                return deduplicated(fileEvent, isManualCapture: isManualCapture)
            }

            if let dataEvent = try readImageFromData(now: now) {
                return deduplicated(dataEvent, isManualCapture: isManualCapture)
            }

            if let image = pasteboard.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage {
                let event = ImageCaptureEvent(
                    timestamp: now,
                    image: image,
                    source: .copy,
                    fingerprint: fingerprint(for: image, salt: changeCount)
                )
                return deduplicated(event, isManualCapture: isManualCapture)
            }
        } catch {
            logger.error("Pasteboard read failed: \(error.localizedDescription)")
        }

        return nil
    }

    private func readImageFromFileURL(now: Date) throws -> ImageCaptureEvent? {
        guard let url = pasteboard.readObjects(forClasses: [NSURL.self], options: nil)?.first as? URL else {
            return nil
        }

        let supportedExtensions = Set(["png", "jpg", "jpeg", "heic", "tif", "tiff"])
        let pathExtension = url.pathExtension.lowercased()
        guard supportedExtensions.contains(pathExtension) else {
            return nil
        }

        guard let image = NSImage(contentsOf: url) else {
            return nil
        }

        let source: ImageCaptureEvent.ClipboardSource = url.lastPathComponent.localizedCaseInsensitiveContains("screen")
            ? .screenshot
            : .drag

        return ImageCaptureEvent(
            timestamp: now,
            image: image,
            source: source,
            fingerprint: fingerprint(for: image, salt: url.path.hashValue)
        )
    }

    private func readImageFromData(now: Date) throws -> ImageCaptureEvent? {
        let supportedTypes: [NSPasteboard.PasteboardType] = [
            .png,
            .tiff,
            NSPasteboard.PasteboardType("public.jpeg"),
            NSPasteboard.PasteboardType("public.heic"),
        ]

        for type in supportedTypes where pasteboard.types?.contains(type) == true {
            guard let data = pasteboard.data(forType: type), let image = NSImage(data: data) else {
                logger.debug("Skipping unreadable pasteboard image data for type \(type.rawValue, privacy: .public)")
                continue
            }

            let source: ImageCaptureEvent.ClipboardSource = type == .png ? .screenshot : .copy

            return ImageCaptureEvent(
                timestamp: now,
                image: image,
                source: source,
                fingerprint: data.hashValue
            )
        }

        return nil
    }

    private func deduplicated(_ event: ImageCaptureEvent, isManualCapture: Bool) -> ImageCaptureEvent? {
        if !isManualCapture,
            lastFingerprint == event.fingerprint,
            event.timestamp.timeIntervalSince(lastCaptureTime) < debounceInterval
        {
            logger.debug("Duplicate pasteboard image ignored")
            return nil
        }

        lastFingerprint = event.fingerprint
        lastCaptureTime = event.timestamp
        logger.info("Clipboard image emitted from \(event.source.rawValue, privacy: .public)")
        return event
    }

    private func fingerprint(for image: NSImage, salt: Int) -> Int {
        var hasher = Hasher()
        hasher.combine(salt)
        hasher.combine(Int(image.size.width.rounded()))
        hasher.combine(Int(image.size.height.rounded()))
        hasher.combine(image.tiffRepresentation?.hashValue ?? 0)
        return hasher.finalize()
    }

    deinit {
        timer?.invalidate()
    }
}
