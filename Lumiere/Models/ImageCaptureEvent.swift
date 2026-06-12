import AppKit
import Foundation

/// Image capture event from clipboard monitoring.
/// Uses `@unchecked Sendable` because NSImage is not Sendable in Apple frameworks.
/// Instances are created on the main thread and consumed on the main thread via Combine publishers.
struct ImageCaptureEvent: @unchecked Sendable {
    let timestamp: Date
    let image: NSImage
    let source: ClipboardSource
    let fingerprint: Int

    enum ClipboardSource: String, Sendable {
        case screenshot
        case copy
        case drag
    }
}
