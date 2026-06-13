import AppKit
import Combine
import XCTest
@testable import Lumiere

final class LumiereModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables.removeAll()
        NSPasteboard.general.clearContents()
        super.tearDown()
    }

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
        let imageURL = fixtureImageURL()

        pasteboard.clearContents()
        XCTAssertTrue(pasteboard.writeObjects([imageURL as NSURL]))

        let service = ClipboardMonitorService()
        let event = try XCTUnwrap(service.captureCurrentPasteboardImage())

        XCTAssertEqual(event.source, .drag)
        XCTAssertEqual(event.image.size.width, 512, accuracy: 0.1)
        XCTAssertEqual(event.image.size.height, 512, accuracy: 0.1)
        XCTAssertGreaterThanOrEqual(pasteboard.changeCount, previousChangeCount)
    }

    func testClipboardMonitorPublishesAfterStopStartRestart() throws {
        let pasteboard = NSPasteboard.general
        let image = try XCTUnwrap(NSImage(contentsOf: fixtureImageURL()))
        let emitted = expectation(description: "clipboard monitor emits after restart")

        pasteboard.clearContents()
        let service = ClipboardMonitorService()
        service.startMonitoring()
        service.stopMonitoring()

        service.imagePublisher
            .sink { event in
                XCTAssertEqual(event.image.size.width, 512, accuracy: 0.1)
                emitted.fulfill()
            }
            .store(in: &cancellables)

        service.startMonitoring()
        pasteboard.clearContents()
        XCTAssertTrue(pasteboard.writeObjects([image]))

        wait(for: [emitted], timeout: 2.0)
        service.stopMonitoring()
    }

    func testClipboardMonitorFallsBackPastCorruptPNGToValidTIFF() throws {
        let pasteboard = NSPasteboard.general
        let image = try XCTUnwrap(NSImage(contentsOf: fixtureImageURL()))
        let tiff = try XCTUnwrap(image.tiffRepresentation)

        pasteboard.clearContents()
        pasteboard.declareTypes([.png, .tiff], owner: nil)
        XCTAssertTrue(pasteboard.setData(Data("not-a-png".utf8), forType: .png))
        XCTAssertTrue(pasteboard.setData(tiff, forType: .tiff))

        let service = ClipboardMonitorService()
        let event = try XCTUnwrap(service.captureCurrentPasteboardImage())
        XCTAssertEqual(event.image.size.width, 512, accuracy: 0.1)
        XCTAssertEqual(event.image.size.height, 512, accuracy: 0.1)
    }

    func testAnnotationExportCoordinateMapperMatchesPreviewTopLeftSemantics() {
        let canvasSize = CGSize(width: 100, height: 100)
        let previewRect = CGRect(x: 0.10, y: 0.10, width: 0.20, height: 0.20)
        let exportRect = AnnotationExportCoordinates.rect(previewRect, in: canvasSize)
        let exportPoint = AnnotationExportCoordinates.point(CGPoint(x: 0.25, y: 0.10), in: canvasSize)

        XCTAssertEqual(exportRect.origin.x, 10, accuracy: 0.001)
        XCTAssertEqual(exportRect.origin.y, 70, accuracy: 0.001)
        XCTAssertEqual(exportRect.width, 20, accuracy: 0.001)
        XCTAssertEqual(exportRect.height, 20, accuracy: 0.001)
        XCTAssertEqual(exportPoint.x, 25, accuracy: 0.001)
        XCTAssertEqual(exportPoint.y, 90, accuracy: 0.001)
    }

    func testAnnotationJSONRoundTripKeepsAllToolPayloads() throws {
        let annotations: [Annotation] = [
            .arrow(ArrowAnnotation(start: CGPoint(x: 0.1, y: 0.2), end: CGPoint(x: 0.8, y: 0.6))),
            .shape(ShapeAnnotation(type: .rectangle, rect: CGRect(x: 0.2, y: 0.3, width: 0.2, height: 0.1), fillColorHex: "#112233")),
            .text(TextAnnotation(content: "Smoke", position: CGPoint(x: 0.4, y: 0.2))),
            .callout(CalloutAnnotation(text: "Callout", targetPosition: CGPoint(x: 0.5, y: 0.3), tailPosition: CGPoint(x: 0.6, y: 0.7))),
            .blur(BlurAnnotation(rect: CGRect(x: 0.1, y: 0.1, width: 0.3, height: 0.2))),
        ]

        let service = AnnotationRenderingService()
        let data = try service.exportAnnotationData(annotations)
        let decoded = try service.importAnnotationData(data)

        XCTAssertEqual(decoded.count, annotations.count)
        XCTAssertEqual(decoded.map(\.id), annotations.map(\.id))
    }

    func testVoltHexColorParsesToExpectedComponents() throws {
        let color = try XCTUnwrap(NSColor(hex: "#C8FF00")?.usingColorSpace(.sRGB))

        XCTAssertEqual(color.redComponent, 200.0 / 255.0, accuracy: 0.001)
        XCTAssertEqual(color.greenComponent, 1.0, accuracy: 0.001)
        XCTAssertEqual(color.blueComponent, 0.0, accuracy: 0.001)
        XCTAssertEqual(color.alphaComponent, 1.0, accuracy: 0.001)
    }

    private func fixtureImageURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Lumiere/Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512.png")
    }

}
