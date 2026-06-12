import AppKit
import CoreImage
import CoreVideo
import Vision

final class ImageProcessingPipeline: Sendable {
    enum ProcessingError: LocalizedError {
        case processingFailure(String)
        case cornerDetectionFailure
        case invalidTransform
        case insufficientShadowData

        var errorDescription: String? {
            switch self {
            case .processingFailure(let operation):
                return "Image processing failed during \(operation)."
            case .cornerDetectionFailure:
                return "No rectangular document edges were detected."
            case .invalidTransform:
                return "Perspective correction could not construct a valid transform."
            case .insufficientShadowData:
                return "Insufficient shadow data in the image for correction."
            }
        }
    }

    private let logger = LumiereLogger.imageProcessing
    private let coreMLService: CoreMLInferenceService
    private let maximumDimension: CGFloat = 8192

    init(coreMLService: CoreMLInferenceService = CoreMLInferenceService()) {
        self.coreMLService = coreMLService
    }

    func processShadow(image: NSImage, params: ShadowParams) async throws -> ProcessedImage {
        let preparedImage = resizedIfNeeded(image)
        let pixelBuffer = makePixelBuffer(from: preparedImage)
        let inference: InferenceResult?
        if let pixelBuffer, let metrics = try? CoreMLInferenceService.sampleMetrics(from: pixelBuffer) {
            inference = try? await coreMLService.infer(.shadowDetection, metrics: metrics)
        } else {
            inference = nil
        }
        let confidence = inference?.confidence ?? params.intensity
        let startTime = Date()

        guard let cgImage = preparedImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ProcessingError.processingFailure("CGImage conversion")
        }

        let ciContext = CIContext()
        let baseImage = CIImage(cgImage: cgImage)

        let shadowMask = baseImage
            .applyingFilter("CIColorControls", parameters: [
                kCIInputBrightnessKey: -0.2,
                kCIInputSaturationKey: 0,
                kCIInputContrastKey: 1.1,
            ])
            .applyingFilter("CIGaussianBlur", parameters: [
                kCIInputRadiusKey: params.blurRadius,
            ])
            .applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: CGFloat(params.intensity)),
            ])
            .transformed(by: .init(translationX: params.direction.dx, y: -params.direction.dy))

        // Shadow goes behind the base image
        let composed = baseImage.applyingFilter("CISourceOverCompositing", parameters: [
            kCIInputBackgroundImageKey: shadowMask,
        ])

        let renderRect = baseImage.extent.insetBy(dx: -(params.blurRadius * 2), dy: -(params.blurRadius * 2))
        guard let outputCGImage = ciContext.createCGImage(composed, from: renderRect) else {
            throw ProcessingError.processingFailure("CIContext rendering")
        }

        let resultImage = NSImage(cgImage: outputCGImage, size: renderRect.size)
        let duration = Date().timeIntervalSince(startTime)
        logger.info("Shadow processing completed in \(duration * 1000, format: .fixed(precision: 2))ms")

        return ProcessedImage(
            image: resultImage,
            confidence: confidence,
            processingTime: duration,
            transformMatrix: nil
        )
    }

    func detectCorners(image: NSImage) async throws -> [CGPoint] {
        let preparedImage = resizedIfNeeded(image)
        guard let cgImage = preparedImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ProcessingError.cornerDetectionFailure
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectRectanglesRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observation = (request.results as? [VNRectangleObservation])?.first else {
                    continuation.resume(throwing: ProcessingError.cornerDetectionFailure)
                    return
                }

                continuation.resume(returning: [
                    observation.topLeft,
                    observation.topRight,
                    observation.bottomRight,
                    observation.bottomLeft,
                ])
            }

            request.minimumSize = 0.15
            request.minimumConfidence = 0.5
            request.maximumObservations = 1
            request.quadratureTolerance = 25

            do {
                try VNImageRequestHandler(cgImage: cgImage).perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func correctPerspective(image: NSImage, corners: [CGPoint]) async throws -> ProcessedImage {
        guard corners.count == 4 else {
            throw ProcessingError.cornerDetectionFailure
        }

        let preparedImage = resizedIfNeeded(image)
        let pixelBuffer = makePixelBuffer(from: preparedImage)
        let inference: InferenceResult?
        if let pixelBuffer, let metrics = try? CoreMLInferenceService.sampleMetrics(from: pixelBuffer) {
            inference = try? await coreMLService.infer(.perspectiveCorrection, metrics: metrics)
        } else {
            inference = nil
        }
        let startTime = Date()

        guard let cgImage = preparedImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ProcessingError.processingFailure("CGImage conversion")
        }

        let ciContext = CIContext()
        let ciImage = CIImage(cgImage: cgImage)
        let extent = ciImage.extent

        func denormalize(_ point: CGPoint) -> CIVector {
            CIVector(x: point.x * extent.width, y: point.y * extent.height)
        }

        let corrected = ciImage.applyingFilter("CIPerspectiveCorrection", parameters: [
            "inputTopLeft": denormalize(corners[0]),
            "inputTopRight": denormalize(corners[1]),
            "inputBottomRight": denormalize(corners[2]),
            "inputBottomLeft": denormalize(corners[3]),
        ])

        let outputExtent = corrected.extent.integral
        guard !outputExtent.isNull, let outputCGImage = ciContext.createCGImage(corrected, from: outputExtent) else {
            throw ProcessingError.invalidTransform
        }

        let transform = CGAffineTransform(translationX: -outputExtent.minX, y: -outputExtent.minY)
        let resultImage = NSImage(cgImage: outputCGImage, size: outputExtent.size)
        let duration = Date().timeIntervalSince(startTime)
        logger.info("Perspective correction completed in \(duration * 1000, format: .fixed(precision: 2))ms")

        return ProcessedImage(
            image: resultImage,
            confidence: inference?.confidence ?? 0.9,
            processingTime: duration,
            transformMatrix: transform
        )
    }

    func processBatch(_ operations: [ProcessingOperation]) async -> [ProcessedImage] {
        let prioritizedOperations = operations.sorted { $0.priority > $1.priority }

        return await withTaskGroup(of: (Int, ProcessedImage).self) { group in
            for (index, operation) in prioritizedOperations.enumerated() {
                group.addTask {
                    switch operation {
                    case .shadow(let image, let params, _):
                        do {
                            return (index, try await self.processShadow(image: image, params: params))
                        } catch {
                            return (index, ProcessedImage(image: image, confidence: 0, processingTime: 0, transformMatrix: nil))
                        }
                    case .perspective(let image, let corners, _):
                        do {
                            return (index, try await self.correctPerspective(image: image, corners: corners))
                        } catch {
                            self.logger.error("Batch perspective operation failed: \(error.localizedDescription)")
                            return (index, ProcessedImage(image: image, confidence: 0, processingTime: 0, transformMatrix: nil))
                        }
                    }
                }
            }

            var indexed: [(Int, ProcessedImage)] = []
            for await result in group {
                indexed.append(result)
            }
            return indexed.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }

    private nonisolated func resizedIfNeeded(_ image: NSImage) -> NSImage {
        let longestEdge = max(image.size.width, image.size.height)
        guard longestEdge > maximumDimension else { return image }

        let scale = maximumDimension / longestEdge
        let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let resized = NSImage(size: targetSize)
        resized.lockFocus()
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        resized.unlockFocus()
        return resized
    }

    private nonisolated func makePixelBuffer(from image: NSImage) -> CVPixelBuffer? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }

        let attributes: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
        ]

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            cgImage.width,
            cgImage.height,
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pixelBuffer),
            width: cgImage.width,
            height: cgImage.height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        return pixelBuffer
    }
}
