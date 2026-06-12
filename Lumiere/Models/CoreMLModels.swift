import CoreML
import Foundation

enum ModelType: String, CaseIterable, Sendable {
    case shadowDetection = "ShadowDetection"
    case perspectiveCorrection = "PerspectiveCorrection"
}

/// Result of a Core ML inference operation.
/// Uses `@unchecked Sendable` because MLFeatureValue is not Sendable in Apple frameworks.
/// Instances are created within the CoreMLInferenceService actor and read after awaiting.
struct InferenceResult: @unchecked Sendable {
    let predictions: [MLFeatureValue]
    let confidence: Float
    let processingTime: TimeInterval
}
