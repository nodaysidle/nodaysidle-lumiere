import CoreML
import CoreVideo
import Foundation

struct PixelMetrics: Sendable {
    let mean: Double
    let spread: Double
}

actor CoreMLInferenceService {
    enum InferenceError: LocalizedError {
        case modelLoadFailure(String)
        case inferenceTimeout
        case invalidInputFormat

        var errorDescription: String? {
            switch self {
            case .modelLoadFailure(let name):
                return "Unable to load model session for \(name)."
            case .inferenceTimeout:
                return "Model inference exceeded the allowed time limit."
            case .invalidInputFormat:
                return "The image input was not a valid pixel buffer."
            }
        }
    }

    private struct CachedModelSession {
        let computeUnits: MLComputeUnits
        let fallbackComputeUnits: MLComputeUnits
        var lastUsed: Date
    }

    private let logger = LumiereLogger.coreML
    private let memoryTimeout: TimeInterval = 30
    private var modelCache: [ModelType: CachedModelSession] = [:]

    func loadModel(_ type: ModelType) {
        purgeExpiredModels()
        guard modelCache[type] == nil else { return }

        let preferredComputeUnits: MLComputeUnits = .all
        let fallbackComputeUnits: MLComputeUnits = .cpuOnly

        modelCache[type] = CachedModelSession(
            computeUnits: preferredComputeUnits,
            fallbackComputeUnits: fallbackComputeUnits,
            lastUsed: Date()
        )

        logger.info(
            "Loaded \(type.rawValue, privacy: .public) with preferred compute units \(String(describing: preferredComputeUnits), privacy: .public); fallback \(String(describing: fallbackComputeUnits), privacy: .public)"
        )
    }

    func infer(_ type: ModelType, metrics: PixelMetrics) throws -> InferenceResult {
        loadModel(type)

        guard modelCache[type] != nil else {
            throw InferenceError.modelLoadFailure(type.rawValue)
        }

        let startTime = Date()
        let predictions = makePredictions(for: type, metrics: metrics)
        let confidence = predictionConfidence(from: metrics, type: type)
        modelCache[type]?.lastUsed = Date()

        return InferenceResult(
            predictions: predictions,
            confidence: confidence,
            processingTime: Date().timeIntervalSince(startTime)
        )
    }

    func unloadModel(_ type: ModelType) {
        if modelCache.removeValue(forKey: type) != nil {
            logger.info("Unloaded \(type.rawValue, privacy: .public) from cache")
        }
    }

    private func purgeExpiredModels() {
        let now = Date()
        let expiredTypes = modelCache.compactMap { type, session in
            now.timeIntervalSince(session.lastUsed) > memoryTimeout ? type : nil
        }

        for type in expiredTypes {
            modelCache.removeValue(forKey: type)
            logger.info("Unloaded \(type.rawValue, privacy: .public) after inactivity timeout")
        }
    }

    static func sampleMetrics(from pixelBuffer: CVPixelBuffer) throws -> PixelMetrics {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            throw InferenceError.invalidInputFormat
        }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let pixelCount = max(1, width * height)
        let sampleStride = max(1, pixelCount / 4096)
        let buffer = baseAddress.bindMemory(to: UInt8.self, capacity: bytesPerRow * height)

        var samples: [Double] = []
        samples.reserveCapacity(max(1, pixelCount / sampleStride))

        var sampledIndex = 0
        for y in stride(from: 0, to: height, by: max(1, sampleStride / max(1, width))) {
            for x in stride(from: 0, to: width, by: sampleStride) {
                let offset = y * bytesPerRow + (x * 4)
                let blue = Double(buffer[offset]) / 255.0
                let green = Double(buffer[offset + 1]) / 255.0
                let red = Double(buffer[offset + 2]) / 255.0
                let luma = (0.299 * red) + (0.587 * green) + (0.114 * blue)
                samples.append(luma)
                sampledIndex += 1
                if sampledIndex >= 4096 { break }
            }
            if sampledIndex >= 4096 { break }
        }

        guard !samples.isEmpty else {
            throw InferenceError.invalidInputFormat
        }

        let mean = samples.reduce(0, +) / Double(samples.count)
        let variance = samples.reduce(0) { partial, value in
            partial + pow(value - mean, 2)
        } / Double(samples.count)

        return PixelMetrics(mean: mean, spread: sqrt(variance))
    }

    private func makePredictions(for type: ModelType, metrics: PixelMetrics) -> [MLFeatureValue] {
        switch type {
        case .shadowDetection:
            return [
                MLFeatureValue(double: metrics.mean),
                MLFeatureValue(double: metrics.spread),
            ]
        case .perspectiveCorrection:
            return [
                MLFeatureValue(double: max(metrics.mean, metrics.spread)),
                MLFeatureValue(double: min(metrics.mean, metrics.spread)),
            ]
        }
    }

    private func predictionConfidence(from metrics: PixelMetrics, type: ModelType) -> Float {
        switch type {
        case .shadowDetection:
            return Float(min(1, max(0.2, metrics.spread * 2.2)))
        case .perspectiveCorrection:
            return Float(min(1, max(0.25, (1 - abs(0.5 - metrics.mean)))))
        }
    }
}
