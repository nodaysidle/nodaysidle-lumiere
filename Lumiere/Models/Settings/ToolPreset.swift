import Foundation

struct ToolPreset: Codable, Identifiable, Sendable {
    var id: UUID
    var name: String
    var shadowIntensity: Float
    var perspectiveSensitivity: Float
    var annotationDefaults: [String: String]

    init(
        id: UUID = UUID(),
        name: String,
        shadowIntensity: Float = 0.55,
        perspectiveSensitivity: Float = 0.7,
        annotationDefaults: [String: String] = ["tool": AnnotationTool.arrow.rawValue]
    ) {
        self.id = id
        self.name = name
        self.shadowIntensity = max(0, min(1, shadowIntensity))
        self.perspectiveSensitivity = max(0, min(1, perspectiveSensitivity))
        self.annotationDefaults = annotationDefaults
    }

    static func defaultPresets() -> [ToolPreset] {
        [
            ToolPreset(
                name: "Studio",
                shadowIntensity: 0.65,
                perspectiveSensitivity: 0.75,
                annotationDefaults: ["tool": AnnotationTool.arrow.rawValue]
            ),
            ToolPreset(
                name: "Docs",
                shadowIntensity: 0.45,
                perspectiveSensitivity: 0.85,
                annotationDefaults: ["tool": AnnotationTool.rectangle.rawValue]
            ),
        ]
    }
}
