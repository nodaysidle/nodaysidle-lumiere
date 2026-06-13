import CoreGraphics

enum AnnotationExportCoordinates {
    /// Converts the normalized top-left annotation coordinate space used by SwiftUI preview
    /// into the bottom-left AppKit drawing coordinate space used by NSImage export.
    static func point(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: point.x * size.width, y: (1 - point.y) * size.height)
    }

    /// Converts a normalized top-left rect into AppKit export coordinates while preserving
    /// the visual top-left placement users see in the live preview canvas.
    static func rect(_ rect: CGRect, in size: CGSize) -> CGRect {
        CGRect(
            x: rect.origin.x * size.width,
            y: (1 - rect.origin.y - rect.size.height) * size.height,
            width: rect.size.width * size.width,
            height: rect.size.height * size.height
        )
    }
}
