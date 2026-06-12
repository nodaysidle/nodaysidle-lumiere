import AppKit
import CoreGraphics
import Foundation

enum AnnotationTool: String, CaseIterable, Codable, Sendable, Identifiable {
    case arrow
    case rectangle
    case text
    case callout
    case blur

    var id: Self { self }

    var title: String {
        switch self {
        case .arrow:
            return "Arrow"
        case .rectangle:
            return "Rectangle"
        case .text:
            return "Text"
        case .callout:
            return "Callout"
        case .blur:
            return "Blur"
        }
    }

    var symbolName: String {
        switch self {
        case .arrow:
            return "arrow.up.right"
        case .rectangle:
            return "rectangle"
        case .text:
            return "text.cursor"
        case .callout:
            return "bubble.left.and.exclamationmark.bubble.right"
        case .blur:
            return "drop.halffull"
        }
    }
}

enum Annotation: Codable, Sendable, Identifiable {
    case arrow(ArrowAnnotation)
    case shape(ShapeAnnotation)
    case text(TextAnnotation)
    case callout(CalloutAnnotation)
    case blur(BlurAnnotation)

    var id: UUID {
        switch self {
        case .arrow(let annotation):
            return annotation.id
        case .shape(let annotation):
            return annotation.id
        case .text(let annotation):
            return annotation.id
        case .callout(let annotation):
            return annotation.id
        case .blur(let annotation):
            return annotation.id
        }
    }
}

struct ArrowAnnotation: Codable, Sendable, Identifiable {
    var id = UUID()
    var start: CGPoint
    var end: CGPoint
    var colorHex: String = "#C8FF00"
    var thickness: CGFloat = 3

    var color: CGColor {
        NSColor(hex: colorHex)?.cgColor ?? NSColor.systemGreen.cgColor
    }
}

struct ShapeAnnotation: Codable, Sendable, Identifiable {
    enum ShapeType: String, Codable, Sendable {
        case rectangle
        case oval
        case line
    }

    var id = UUID()
    var type: ShapeType
    var rect: CGRect
    var fillColorHex: String?
    var strokeColorHex: String = "#C8FF00"
    var strokeWidth: CGFloat = 3

    var strokeColor: CGColor {
        NSColor(hex: strokeColorHex)?.cgColor ?? NSColor.systemGreen.cgColor
    }

    var fillColor: CGColor? {
        guard let fillColorHex else { return nil }
        return NSColor(hex: fillColorHex)?.cgColor
    }
}

struct TextAnnotation: Codable, Sendable, Identifiable {
    var id = UUID()
    var content: String
    var position: CGPoint
    var fontSize: CGFloat = 18
    var fontColorHex: String = "#F0F0F5"
    var backgroundColorHex: String? = "#14141F"

    var fontColor: CGColor {
        NSColor(hex: fontColorHex)?.cgColor ?? NSColor.labelColor.cgColor
    }

    var backgroundColor: CGColor? {
        guard let backgroundColorHex else { return nil }
        return NSColor(hex: backgroundColorHex)?.cgColor
    }
}

struct CalloutAnnotation: Codable, Sendable, Identifiable {
    var id = UUID()
    var text: String
    var targetPosition: CGPoint
    var tailPosition: CGPoint
    var fontSize: CGFloat = 14
    var fontColorHex: String = "#0A0A0F"
    var fillColorHex: String = "#C8FF00"

    var fontColor: CGColor {
        NSColor(hex: fontColorHex)?.cgColor ?? NSColor.labelColor.cgColor
    }

    var fillColor: CGColor {
        NSColor(hex: fillColorHex)?.cgColor ?? NSColor.systemGreen.cgColor
    }
}

struct BlurAnnotation: Codable, Sendable, Identifiable {
    var id = UUID()
    var rect: CGRect
    var blurRadius: CGFloat = 12
}

extension NSColor {
    convenience init?(hex: String) {
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        value = value.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: value).scanHexInt64(&rgb) else { return nil }

        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let alpha: CGFloat

        switch value.count {
        case 6:
            red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            blue = CGFloat(rgb & 0x0000FF) / 255.0
            alpha = 1
        case 8:
            red = CGFloat((rgb & 0xFF00_0000) >> 24) / 255.0
            green = CGFloat((rgb & 0x00FF_0000) >> 16) / 255.0
            blue = CGFloat((rgb & 0x0000_FF00) >> 8) / 255.0
            alpha = CGFloat(rgb & 0x0000_00FF) / 255.0
        default:
            return nil
        }

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
