import AppKit
import XCTest
@testable import Lumiere

final class LumiereModelTests: XCTestCase {
    func testShadowParamsClampIntensityIntoSafeRange() {
        XCTAssertEqual(ShadowParams(intensity: -1).intensity, 0)
        XCTAssertEqual(ShadowParams(intensity: 2).intensity, 1)
        XCTAssertTrue(ShadowParams(intensity: 0.42).isValid)
    }

    func testAnnotationToolsExposeStableUserFacingLabelsAndSymbols() {
        let tools = AnnotationTool.allCases

        XCTAssertEqual(tools.map(\.title), ["Arrow", "Rectangle", "Text", "Callout", "Blur"])
        XCTAssertEqual(tools.map(\.symbolName), [
            "arrow.up.right",
            "rectangle",
            "text.cursor",
            "bubble.left.and.exclamationmark.bubble.right",
            "drop.halffull",
        ])
    }

    func testClipboardMonitorCapturesImageFileURL() throws {
        let pasteboard = NSPasteboard.general
        let previousChangeCount = pasteboard.changeCount
        let imageURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Lumiere/Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512.png")

        pasteboard.clearContents()
        XCTAssertTrue(pasteboard.writeObjects([imageURL as NSURL]))

        let service = ClipboardMonitorService()
        let event = try XCTUnwrap(service.captureCurrentPasteboardImage())

        XCTAssertEqual(event.source, .drag)
        XCTAssertEqual(event.image.size.width, 512, accuracy: 0.1)
        XCTAssertEqual(event.image.size.height, 512, accuracy: 0.1)
        XCTAssertGreaterThanOrEqual(pasteboard.changeCount, previousChangeCount)
    }

    func testVoltHexColorParsesToExpectedComponents() throws {
        let color = try XCTUnwrap(NSColor(hex: "#C8FF00")?.usingColorSpace(.sRGB))

        XCTAssertEqual(color.redComponent, 200.0 / 255.0, accuracy: 0.001)
        XCTAssertEqual(color.greenComponent, 1.0, accuracy: 0.001)
        XCTAssertEqual(color.blueComponent, 0.0, accuracy: 0.001)
        XCTAssertEqual(color.alphaComponent, 1.0, accuracy: 0.001)
    }
}
