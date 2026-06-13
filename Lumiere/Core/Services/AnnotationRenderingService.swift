import AppKit
import Foundation

final class AnnotationRenderingService {
    enum RenderingError: LocalizedError {
        case invalidAnnotationData

        var errorDescription: String? {
            "Annotation data could not be sanitized for rendering."
        }
    }

    private let logger = LumiereLogger.annotation

    func render(annotations: [Annotation], onto baseImage: NSImage) -> NSImage {
        let imageSize = baseImage.size
        let output = NSImage(size: imageSize)
        output.lockFocus()
        defer { output.unlockFocus() }

        baseImage.draw(in: CGRect(origin: .zero, size: imageSize))

        for annotation in annotations {
            render(annotation, canvasSize: imageSize, baseImage: baseImage)
        }

        return output
    }

    func exportAnnotationData(_ annotations: [Annotation]) throws -> Data {
        try JSONEncoder().encode(annotations)
    }

    func importAnnotationData(_ data: Data) throws -> [Annotation] {
        try JSONDecoder().decode([Annotation].self, from: data)
    }

    func createAnnotationLayer() -> AnnotationLayer {
        AnnotationLayer()
    }

    func sanitizePath(_ points: [CGPoint], maxPoints: Int = 1000) -> [CGPoint]? {
        guard points.count <= maxPoints else { return nil }
        return points.compactMap(sanitize)
    }

    private func render(_ annotation: Annotation, canvasSize: CGSize, baseImage: NSImage) {
        switch annotation {
        case .arrow(let annotation):
            renderArrow(annotation, canvasSize: canvasSize)
        case .shape(let annotation):
            renderShape(annotation, canvasSize: canvasSize)
        case .text(let annotation):
            renderText(annotation, canvasSize: canvasSize)
        case .callout(let annotation):
            renderCallout(annotation, canvasSize: canvasSize)
        case .blur(let annotation):
            renderBlur(annotation, canvasSize: canvasSize, baseImage: baseImage)
        }
    }

    private func renderArrow(_ annotation: ArrowAnnotation, canvasSize: CGSize) {
        guard
            let start = sanitize(annotation.start),
            let end = sanitize(annotation.end),
            let context = NSGraphicsContext.current?.cgContext
        else {
            logger.error("Arrow annotation rejected during sanitization")
            return
        }

        let startPoint = denormalize(start, in: canvasSize)
        let endPoint = denormalize(end, in: canvasSize)
        context.setStrokeColor(annotation.color)
        context.setLineWidth(annotation.thickness)
        context.setLineCap(.round)
        context.move(to: startPoint)
        context.addLine(to: endPoint)
        context.strokePath()

        let angle = atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x)
        let arrowSize: CGFloat = 16
        let arrowHead = CGMutablePath()
        arrowHead.move(to: endPoint)
        arrowHead.addLine(to: CGPoint(
            x: endPoint.x - arrowSize * cos(angle - .pi / 7),
            y: endPoint.y - arrowSize * sin(angle - .pi / 7)
        ))
        arrowHead.addLine(to: CGPoint(
            x: endPoint.x - arrowSize * cos(angle + .pi / 7),
            y: endPoint.y - arrowSize * sin(angle + .pi / 7)
        ))
        arrowHead.closeSubpath()

        context.setFillColor(annotation.color)
        context.addPath(arrowHead)
        context.fillPath()
    }

    private func renderShape(_ annotation: ShapeAnnotation, canvasSize: CGSize) {
        guard let rect = sanitize(annotation.rect), let context = NSGraphicsContext.current?.cgContext else {
            logger.error("Shape annotation rejected during sanitization")
            return
        }

        let drawingRect = denormalize(rect, in: canvasSize)
        context.setLineWidth(annotation.strokeWidth)
        context.setStrokeColor(annotation.strokeColor)

        if let fillColor = annotation.fillColor {
            context.setFillColor(fillColor)
        }

        switch annotation.type {
        case .rectangle:
            if annotation.fillColor != nil { context.fill(drawingRect) }
            context.stroke(drawingRect)
        case .oval:
            if annotation.fillColor != nil { context.fillEllipse(in: drawingRect) }
            context.strokeEllipse(in: drawingRect)
        case .line:
            context.move(to: drawingRect.origin)
            context.addLine(to: CGPoint(x: drawingRect.maxX, y: drawingRect.maxY))
            context.strokePath()
        }
    }

    private func renderText(_ annotation: TextAnnotation, canvasSize: CGSize) {
        guard let point = sanitize(annotation.position) else {
            logger.error("Text annotation rejected during sanitization")
            return
        }

        let resolvedPoint = denormalize(point, in: canvasSize)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: annotation.fontSize, weight: .semibold),
            .foregroundColor: NSColor(cgColor: annotation.fontColor) ?? .labelColor,
        ]

        let string = NSAttributedString(string: annotation.content, attributes: attributes)
        let textSize = string.size()

        if let backgroundColor = annotation.backgroundColor, let context = NSGraphicsContext.current?.cgContext {
            context.setFillColor(backgroundColor)
            context.fill(CGRect(
                x: resolvedPoint.x - 10,
                y: resolvedPoint.y - textSize.height - 6,
                width: textSize.width + 20,
                height: textSize.height + 12
            ))
        }

        string.draw(at: CGPoint(x: resolvedPoint.x, y: resolvedPoint.y - textSize.height))
    }

    private func renderCallout(_ annotation: CalloutAnnotation, canvasSize: CGSize) {
        guard
            let target = sanitize(annotation.targetPosition),
            let tail = sanitize(annotation.tailPosition),
            let context = NSGraphicsContext.current?.cgContext
        else {
            logger.error("Callout annotation rejected during sanitization")
            return
        }

        let targetPoint = denormalize(target, in: canvasSize)
        let tailPoint = denormalize(tail, in: canvasSize)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: annotation.fontSize, weight: .bold),
            .foregroundColor: NSColor(cgColor: annotation.fontColor) ?? .labelColor,
        ]

        let string = NSAttributedString(string: annotation.text, attributes: attributes)
        let textSize = string.size()
        let bubbleRect = CGRect(
            x: targetPoint.x,
            y: targetPoint.y - textSize.height - 24,
            width: textSize.width + 24,
            height: textSize.height + 16
        )

        context.setFillColor(annotation.fillColor)
        let bubblePath = CGPath(roundedRect: bubbleRect, cornerWidth: 12, cornerHeight: 12, transform: nil)
        context.addPath(bubblePath)
        context.fillPath()

        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: bubbleRect.minX + 18, y: bubbleRect.minY + 8))
        tailPath.addLine(to: tailPoint)
        tailPath.addLine(to: CGPoint(x: bubbleRect.minX + 32, y: bubbleRect.minY + 8))
        tailPath.closeSubpath()
        context.addPath(tailPath)
        context.fillPath()

        string.draw(at: CGPoint(x: bubbleRect.minX + 12, y: bubbleRect.minY + 8))
    }

    private func renderBlur(_ annotation: BlurAnnotation, canvasSize: CGSize, baseImage: NSImage) {
        guard let sanitizedRect = sanitize(annotation.rect) else {
            logger.error("Blur annotation rejected during sanitization")
            return
        }

        let drawingRect = denormalize(sanitizedRect, in: canvasSize)

        guard let cgImage = baseImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return
        }

        let ciContext = CIContext()
        let ciImage = CIImage(cgImage: cgImage)

        // Scale from canvas coordinates to image pixel coordinates
        let scaleX = ciImage.extent.width / canvasSize.width
        let scaleY = ciImage.extent.height / canvasSize.height
        let cropRect = CGRect(
            x: drawingRect.origin.x * scaleX,
            y: (canvasSize.height - drawingRect.origin.y - drawingRect.height) * scaleY,
            width: drawingRect.width * scaleX,
            height: drawingRect.height * scaleY
        ).intersection(ciImage.extent)

        guard !cropRect.isEmpty else { return }

        let cropped = ciImage.cropped(to: cropRect)
        let blurred = cropped.applyingFilter("CIGaussianBlur", parameters: [
            kCIInputRadiusKey: annotation.blurRadius,
        ]).cropped(to: cropRect)

        guard let blurredCG = ciContext.createCGImage(blurred, from: cropRect) else { return }

        let blurredNSImage = NSImage(cgImage: blurredCG, size: drawingRect.size)
        blurredNSImage.draw(in: drawingRect)
    }

    private func sanitize(_ point: CGPoint) -> CGPoint? {
        guard point.x.isFinite, point.y.isFinite else { return nil }
        return CGPoint(x: min(max(point.x, 0), 1), y: min(max(point.y, 0), 1))
    }

    private func sanitize(_ rect: CGRect) -> CGRect? {
        guard
            rect.origin.x.isFinite,
            rect.origin.y.isFinite,
            rect.size.width.isFinite,
            rect.size.height.isFinite,
            rect.size.width >= 0,
            rect.size.height >= 0
        else {
            return nil
        }

        return CGRect(
            x: min(max(rect.origin.x, 0), 1),
            y: min(max(rect.origin.y, 0), 1),
            width: min(max(rect.size.width, 0), 1),
            height: min(max(rect.size.height, 0), 1)
        )
    }

    private func denormalize(_ point: CGPoint, in size: CGSize) -> CGPoint {
        AnnotationExportCoordinates.point(point, in: size)
    }

    private func denormalize(_ rect: CGRect, in size: CGSize) -> CGRect {
        AnnotationExportCoordinates.rect(rect, in: size)
    }
}
