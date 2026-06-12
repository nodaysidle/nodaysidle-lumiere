import Foundation
import SwiftData

enum ThemePreference: String, CaseIterable, Codable, Sendable, Identifiable {
    case darkChalk

    var id: Self { self }
    var displayName: String { "Dark Chalk" }
}

enum ExportFormat: String, CaseIterable, Codable, Sendable, Identifiable {
    case png
    case jpeg
    case heic

    var id: Self { self }
    var displayName: String { rawValue.uppercased() }
}

@Model
final class UserSettings {
    @Attribute(.unique) var id: UUID
    var themePreferenceRawValue: String
    var autoCaptureEnabled: Bool
    var defaultExportFormatRawValue: String
    var recentFiles: [String]
    private var toolPresetsBlob: Data

    var themePreference: ThemePreference {
        get { ThemePreference(rawValue: themePreferenceRawValue) ?? .darkChalk }
        set { themePreferenceRawValue = newValue.rawValue }
    }

    var defaultExportFormat: ExportFormat {
        get { ExportFormat(rawValue: defaultExportFormatRawValue) ?? .png }
        set { defaultExportFormatRawValue = newValue.rawValue }
    }

    var toolPresets: [ToolPreset] {
        get {
            (try? JSONDecoder().decode([ToolPreset].self, from: toolPresetsBlob)) ?? []
        }
        set {
            toolPresetsBlob = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    init(
        id: UUID = UUID(),
        themePreference: ThemePreference = .darkChalk,
        autoCaptureEnabled: Bool = true,
        defaultExportFormat: ExportFormat = .png,
        recentFiles: [String] = [],
        toolPresets: [ToolPreset] = []
    ) {
        self.id = id
        self.themePreferenceRawValue = themePreference.rawValue
        self.autoCaptureEnabled = autoCaptureEnabled
        self.defaultExportFormatRawValue = defaultExportFormat.rawValue
        self.recentFiles = recentFiles
        self.toolPresetsBlob = (try? JSONEncoder().encode(toolPresets)) ?? Data()
    }
}
