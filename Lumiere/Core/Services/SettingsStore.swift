import AppKit
import Foundation
import SwiftData

@MainActor
final class SettingsStore: ObservableObject {
    @Published private(set) var settings: UserSettings
    @Published private(set) var recentFiles: [URL] = []

    private let logger = LumiereLogger.ui
    private let maxRecentFiles = 10
    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!

    init() {
        do {
            let schema = Schema([UserSettings.self])
            let configuration = ModelConfiguration(schema: schema)
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            modelContext = modelContainer.mainContext
            settings = UserSettings()
            settings = loadSettings()
            recentFiles = getRecentFiles()
        } catch {
            logger.fault("Failed to initialize SettingsStore: \(error.localizedDescription) — falling back to in-memory defaults")
            do {
                let schema = Schema([UserSettings.self])
                let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                modelContainer = try ModelContainer(for: schema, configurations: [config])
                modelContext = modelContainer.mainContext
                settings = UserSettings(toolPresets: ToolPreset.defaultPresets())
                modelContext.insert(settings)
                recentFiles = []
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Settings Storage Issue"
                    alert.informativeText = "Lumiere couldn't access its settings store. Your preferences will not be saved this session.\n\nError: \(error.localizedDescription)"
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "Continue")
                    alert.runModal()
                }
                return
            } catch {
                logger.fault("Critical: even in-memory fallback failed: \(error.localizedDescription)")
                modelContainer = try! ModelContainer(for: Schema([UserSettings.self]), configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
                modelContext = modelContainer.mainContext
                settings = UserSettings(toolPresets: ToolPreset.defaultPresets())
                recentFiles = []
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Critical Error"
                    alert.informativeText = "Lumiere encountered a critical initialization error. The app will continue with limited functionality.\n\nError: \(error.localizedDescription)"
                    alert.alertStyle = .critical
                    alert.addButton(withTitle: "Continue")
                    alert.runModal()
                }
                return
            }
        }
    }

    func saveSettings(_ updatedSettings: UserSettings? = nil) -> Bool {
        if let updatedSettings {
            settings = updatedSettings
        }

        ensureSettingsInserted()

        do {
            try modelContext.save()
            recentFiles = getRecentFiles()
            NotificationCenter.default.post(name: .lumiereSettingsChanged, object: nil)
            return true
        } catch {
            logger.error("Failed to save settings: \(error.localizedDescription)")
            return false
        }
    }

    func loadSettings() -> UserSettings {
        do {
            let descriptor = FetchDescriptor<UserSettings>()
            if let existing = try modelContext.fetch(descriptor).first {
                if existing.toolPresets.isEmpty {
                    existing.toolPresets = ToolPreset.defaultPresets()
                    _ = saveSettings(existing)
                }
                return existing
            }

            let defaults = UserSettings(toolPresets: ToolPreset.defaultPresets())
            modelContext.insert(defaults)
            try modelContext.save()
            return defaults
        } catch {
            logger.error("Failed to load settings: \(error.localizedDescription)")
            return UserSettings(toolPresets: ToolPreset.defaultPresets())
        }
    }

    func setThemePreference(_ preference: ThemePreference) {
        objectWillChange.send()
        settings.themePreference = preference
        _ = saveSettings()
    }

    func setAutoCaptureEnabled(_ isEnabled: Bool) {
        objectWillChange.send()
        settings.autoCaptureEnabled = isEnabled
        _ = saveSettings()
    }

    func setDefaultExportFormat(_ format: ExportFormat) {
        objectWillChange.send()
        settings.defaultExportFormat = format
        _ = saveSettings()
    }

    func savePreset(_ preset: ToolPreset) {
        objectWillChange.send()
        var presets = settings.toolPresets
        presets.append(preset)
        settings.toolPresets = presets
        _ = saveSettings()
    }

    func deletePreset(_ preset: ToolPreset) {
        objectWillChange.send()
        settings.toolPresets = settings.toolPresets.filter { $0.id != preset.id }
        _ = saveSettings()
    }

    func applyPreset(_ preset: ToolPreset) {
        objectWillChange.send()
        var presets = settings.toolPresets
        guard let index = presets.firstIndex(where: { $0.id == preset.id }) else { return }
        let selected = presets.remove(at: index)
        presets.insert(selected, at: 0)
        settings.toolPresets = presets
        _ = saveSettings()
    }

    func getRecentFiles() -> [URL] {
        let fileManager = FileManager.default
        let validPaths = settings.recentFiles.filter { fileManager.fileExists(atPath: $0) }

        if validPaths != settings.recentFiles {
            settings.recentFiles = validPaths
            _ = saveSettings()
        }

        return Array(validPaths.prefix(maxRecentFiles)).map(URL.init(fileURLWithPath:))
    }

    func addRecentFile(_ url: URL) {
        objectWillChange.send()
        settings.recentFiles.removeAll { $0 == url.path }
        settings.recentFiles.insert(url.path, at: 0)
        settings.recentFiles = Array(settings.recentFiles.prefix(maxRecentFiles))
        _ = saveSettings()
    }

    func clearRecentFiles() {
        objectWillChange.send()
        settings.recentFiles.removeAll()
        _ = saveSettings()
    }

    private func ensureSettingsInserted() {
        if settings.modelContext == nil {
            modelContext.insert(settings)
        }
    }
}
