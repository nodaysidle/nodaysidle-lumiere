import SwiftUI

struct DrawingLayer: View {
    @Binding var annotations: [Annotation]
    @Binding var activeTool: AnnotationTool

    let isEnabled: Bool

    @State private var dragStart: CGPoint?
    @State private var draftAnnotation: Annotation?

    var body: some View {
        GeometryReader { proxy in
            Canvas { context, _ in
                for annotation in annotations {
                    draw(annotation, in: &context, isDraft: false, canvasSize: proxy.size)
                }

                if let draftAnnotation {
                    draw(draftAnnotation, in: &context, isDraft: true, canvasSize: proxy.size)
                }
            }
            .contentShape(Rectangle())
            .gesture(drawingGesture(in: proxy.size))
            .allowsHitTesting(isEnabled)
        }
    }

    private func drawingGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard isEnabled else { return }

                switch activeTool {
                case .arrow, .rectangle, .blur:
                    let start = dragStart ?? value.startLocation
                    dragStart = start
                    draftAnnotation = makeAnnotation(from: start, to: value.location, canvasSize: size)
                case .text, .callout:
                    break
                }
            }
            .onEnded { value in
                guard isEnabled else { return }
                defer {
                    dragStart = nil
                    draftAnnotation = nil
                }

                switch activeTool {
                case .arrow, .rectangle, .blur:
                    if let draftAnnotation {
                        annotations.append(draftAnnotation)
                    }
                case .text:
                    annotations.append(
                        .text(
                            TextAnnotation(
                                content: "Text",
                                position: normalize(value.location, in: size)
                            )
                        )
                    )
                case .callout:
                    let target = normalize(value.location, in: size)
                    let tail = normalize(
                        CGPoint(x: max(12, value.location.x - 60), y: max(12, value.location.y + 50)),
                        in: size
                    )
                    annotations.append(
                        .callout(
                            CalloutAnnotation(
                                text: "Callout",
                                targetPosition: target,
                                tailPosition: tail
                            )
                        )
                    )
                }
            }
    }

    private func makeAnnotation(from start: CGPoint, to end: CGPoint, canvasSize: CGSize) -> Annotation? {
        switch activeTool {
        case .arrow:
            return .arrow(
                ArrowAnnotation(
                    start: normalize(start, in: canvasSize),
                    end: normalize(end, in: canvasSize)
                )
            )
        case .rectangle:
            let origin = CGPoint(x: min(start.x, end.x), y: min(start.y, end.y))
            let size = CGSize(width: abs(end.x - start.x), height: abs(end.y - start.y))
            return .shape(
                ShapeAnnotation(
                    type: .rectangle,
                    rect: normalize(CGRect(origin: origin, size: size), in: canvasSize),
                    fillColorHex: nil
                )
            )
        case .blur:
            let origin = CGPoint(x: min(start.x, end.x), y: min(start.y, end.y))
            let size = CGSize(width: abs(end.x - start.x), height: abs(end.y - start.y))
            return .blur(
                BlurAnnotation(
                    rect: normalize(CGRect(origin: origin, size: size), in: canvasSize)
                )
            )
        case .text, .callout:
            return nil
        }
    }

    private func draw(_ annotation: Annotation, in context: inout GraphicsContext, isDraft: Bool, canvasSize: CGSize) {
        let opacity = isDraft ? 0.55 : 1.0

        switch annotation {
        case .arrow(let annotation):
            let start = denormalize(annotation.start, in: canvasSize)
            let end = denormalize(annotation.end, in: canvasSize)
            var path = Path()
            path.move(to: start)
            path.addLine(to: end)
            context.stroke(
                path,
                with: .color(color(from: annotation.colorHex).opacity(opacity)),
                style: StrokeStyle(lineWidth: annotation.thickness, lineCap: .round, lineJoin: .round)
            )

            let angle = atan2(end.y - start.y, end.x - start.x)
            let head = Path { path in
                let size: CGFloat = 16
                path.move(to: end)
                path.addLine(to: CGPoint(x: end.x - size * cos(angle - .pi / 7), y: end.y - size * sin(angle - .pi / 7)))
                path.addLine(to: CGPoint(x: end.x - size * cos(angle + .pi / 7), y: end.y - size * sin(angle + .pi / 7)))
                path.closeSubpath()
            }
            context.fill(head, with: .color(color(from: annotation.colorHex).opacity(opacity)))

        case .shape(let annotation):
            let rect = denormalize(annotation.rect, in: canvasSize)
            let path = Path(roundedRect: rect, cornerRadius: 12)
            if let fillColorHex = annotation.fillColorHex {
                context.fill(path, with: .color(color(from: fillColorHex).opacity(0.22 * opacity)))
            }
            context.stroke(
                path,
                with: .color(color(from: annotation.strokeColorHex).opacity(opacity)),
                style: StrokeStyle(lineWidth: annotation.strokeWidth)
            )

        case .text(let annotation):
            let point = denormalize(annotation.position, in: canvasSize)
            let text = Text(annotation.content)
                .font(.system(size: annotation.fontSize, weight: .semibold))
                .foregroundStyle(color(from: annotation.fontColorHex).opacity(opacity))
            let background = Path(roundedRect: CGRect(x: point.x - 10, y: point.y - 14, width: 80, height: 36), cornerRadius: 12)
            if let backgroundColorHex = annotation.backgroundColorHex {
                context.fill(background, with: .color(color(from: backgroundColorHex).opacity(0.78 * opacity)))
            }
            context.draw(text, at: CGPoint(x: point.x + 24, y: point.y + 4), anchor: .center)

        case .callout(let annotation):
            let target = denormalize(annotation.targetPosition, in: canvasSize)
            let tail = denormalize(annotation.tailPosition, in: canvasSize)
            let bubbleRect = CGRect(x: target.x, y: target.y - 40, width: 110, height: 42)
            let bubble = Path(roundedRect: bubbleRect, cornerRadius: 14)
            context.fill(bubble, with: .color(color(from: annotation.fillColorHex).opacity(opacity)))

            let tailPath = Path { path in
                path.move(to: CGPoint(x: bubbleRect.minX + 18, y: bubbleRect.maxY - 4))
                path.addLine(to: tail)
                path.addLine(to: CGPoint(x: bubbleRect.minX + 38, y: bubbleRect.maxY - 4))
                path.closeSubpath()
            }
            context.fill(tailPath, with: .color(color(from: annotation.fillColorHex).opacity(opacity)))

            let text = Text(annotation.text)
                .font(.system(size: annotation.fontSize, weight: .bold))
                .foregroundStyle(color(from: annotation.fontColorHex).opacity(opacity))
            context.draw(text, at: CGPoint(x: bubbleRect.midX, y: bubbleRect.midY), anchor: .center)

        case .blur(let annotation):
            // In the live canvas we render a translucent overlay to indicate the blur region.
            // The actual Gaussian blur is applied at export time by AnnotationRenderingService.
            let rect = denormalize(annotation.rect, in: canvasSize)
            let path = Path(roundedRect: rect, cornerRadius: 8)
            context.fill(path, with: .color(Color.Lumiere.textSecondary.opacity(0.25 * opacity)))
            context.stroke(
                path,
                with: .color(Color.Lumiere.textSecondary.opacity(0.5 * opacity)),
                style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
            )
        }
    }

    private func normalize(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: min(max(point.x / max(size.width, 1), 0), 1),
            y: min(max(point.y / max(size.height, 1), 0), 1)
        )
    }

    private func normalize(_ rect: CGRect, in size: CGSize) -> CGRect {
        CGRect(
            x: min(max(rect.origin.x / max(size.width, 1), 0), 1),
            y: min(max(rect.origin.y / max(size.height, 1), 0), 1),
            width: min(max(rect.width / max(size.width, 1), 0), 1),
            height: min(max(rect.height / max(size.height, 1), 0), 1)
        )
    }

    private func denormalize(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: point.x * size.width, y: point.y * size.height)
    }

    private func denormalize(_ rect: CGRect, in size: CGSize) -> CGRect {
        CGRect(
            x: rect.origin.x * size.width,
            y: rect.origin.y * size.height,
            width: rect.width * size.width,
            height: rect.height * size.height
        )
    }

    private func color(from hex: String) -> Color {
        if let color = NSColor(hex: hex) {
            return Color(nsColor: color)
        }
        return Color.Lumiere.accent
    }
}
