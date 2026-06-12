import AppKit
import CoreGraphics
import Foundation

struct ShadowParams: Codable, Sendable {
    var direction: CGVector
    var intensity: Float
    var blurRadius: CGFloat

    init(
        direction: CGVector = CGVector(dx: 20, dy: 18),
        intensity: Float = 0.55,
        blurRadius: CGFloat = 24
    ) {
        self.direction = direction
        self.intensity = max(0, min(1, intensity))
        self.blurRadius = blurRadius
    }

    var isValid: Bool {
        intensity >= 0 && intensity <= 1
    }
}

/// Processed image result from the image processing pipeline.
/// Uses `@unchecked Sendable` because NSImage is not Sendable in Apple frameworks.
/// Instances are created on background processing contexts and consumed on @MainActor.
struct ProcessedImage: @unchecked Sendable {
    let image: NSImage
    let confidence: Float
    let processingTime: TimeInterval
    let transformMatrix: CGAffineTransform?
}

enum ProcessingPriority: Int, Comparable, Sendable {
    case low = 0
    case normal = 1
    case high = 2

    static func < (lhs: ProcessingPriority, rhs: ProcessingPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// A processing operation to be executed by the pipeline.
/// Uses `@unchecked Sendable` because NSImage is not Sendable in Apple frameworks.
enum ProcessingOperation: @unchecked Sendable {
    case shadow(image: NSImage, params: ShadowParams, priority: ProcessingPriority)
    case perspective(image: NSImage, corners: [CGPoint], priority: ProcessingPriority)

    var priority: ProcessingPriority {
        switch self {
        case .shadow(_, _, let priority), .perspective(_, _, let priority):
            return priority
        }
    }
}
