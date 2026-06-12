import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settingsStore: SettingsStore

    @State private var selectedThemeRawValue = ThemePreference.darkChalk.rawValue
    @State private var autoCaptureEnabled = true
    @State private var selectedExportFormatRawValue = ExportFormat.png.rawValue
    @State private var newPresetName = ""
    @State private var newShadowIntensity = 0.55
    @State private var newPerspectiveSensitivity = 0.7

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                generalSection
                presetsSection
                recentFilesSection
            }
            .padding(20)
        }
        .background(Color.Lumiere.background)
        .frame(minWidth: 500, minHeight: 600)
        .onAppear(perform: syncFromStore)
    }

    private var generalSection: some View {
        settingsCard(title: "General") {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Theme")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.Lumiere.textSecondary)

                    Picker("Theme", selection: $selectedThemeRawValue) {
                        ForEach(ThemePreference.allCases.map(\.rawValue), id: \.self) { rawValue in
                            Text(ThemePreference(rawValue: rawValue)?.displayName ?? rawValue).tag(rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedThemeRawValue) { _, rawValue in
                        if let preference = ThemePreference(rawValue: rawValue) {
                            settingsStore.setThemePreference(preference)
                        }
                    }
                }

                Toggle(isOn: $autoCaptureEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto-capture clipboard images")
                            .foregroundStyle(Color.Lumiere.textPrimary)
                        Text("Poll the pasteboard every 250ms and import new screenshots automatically.")
                            .font(.caption)
                            .foregroundStyle(Color.Lumiere.textSecondary)
                    }
                }
                .toggleStyle(.switch)
                .onChange(of: autoCaptureEnabled) { _, isEnabled in
                    settingsStore.setAutoCaptureEnabled(isEnabled)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Default Export Format")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.Lumiere.textSecondary)

                    Picker("Default Export Format", selection: $selectedExportFormatRawValue) {
                        ForEach(ExportFormat.allCases.map(\.rawValue), id: \.self) { rawValue in
                            Text(ExportFormat(rawValue: rawValue)?.displayName ?? rawValue.uppercased()).tag(rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedExportFormatRawValue) { _, rawValue in
                        if let format = ExportFormat(rawValue: rawValue) {
                            settingsStore.setDefaultExportFormat(format)
                        }
                    }
                }
            }
        }
    }

    private var presetsSection: some View {
        settingsCard(title: "Tool Presets") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(settingsStore.settings.toolPresets) { preset in
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(preset.name)
                                .font(.headline)
                                .foregroundStyle(Color.Lumiere.textPrimary)
                            Text("Shadow \(preset.shadowIntensity, format: .number.precision(.fractionLength(2)))")
                                .font(.caption)
                                .foregroundStyle(Color.Lumiere.textSecondary)
                            Text("Perspective \(preset.perspectiveSensitivity, format: .number.precision(.fractionLength(2)))")
                                .font(.caption)
                                .foregroundStyle(Color.Lumiere.textSecondary)
                        }

                        Spacer()

                        Button("Apply") {
                            settingsStore.applyPreset(preset)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.Lumiere.accent)

                        Button(role: .destructive) {
                            settingsStore.deletePreset(preset)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(14)
                    .background(Color.Lumiere.surface.opacity(0.92))
                    .clipShape(.rect(cornerRadius: 18))
                }

                VStack(alignment: .leading, spacing: 10) {
                    TextField("Preset name", text: $newPresetName)
                        .textFieldStyle(.roundedBorder)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Shadow Intensity")
                            .font(.caption)
                            .foregroundStyle(Color.Lumiere.textSecondary)
                        Slider(value: $newShadowIntensity, in: 0...1)
                            .tint(Color.Lumiere.accent)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Perspective Sensitivity")
                            .font(.caption)
                            .foregroundStyle(Color.Lumiere.textSecondary)
                        Slider(value: $newPerspectiveSensitivity, in: 0...1)
                            .tint(Color.Lumiere.accent)
                    }

                    Button("Save Preset", action: savePreset)
                        .buttonStyle(.borderedProminent)
                        .tint(Color.Lumiere.accent)
                        .disabled(newPresetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(14)
                .background(Color.Lumiere.surface.opacity(0.92))
                .clipShape(.rect(cornerRadius: 18))
            }
        }
    }

    private var recentFilesSection: some View {
        settingsCard(title: "Recent Files") {
            VStack(alignment: .leading, spacing: 10) {
                if settingsStore.recentFiles.isEmpty {
                    Text("No recent exports yet.")
                        .foregroundStyle(Color.Lumiere.textSecondary)
                } else {
                    ForEach(settingsStore.recentFiles, id: \.path) { url in
                        HStack(spacing: 10) {
                            Image(systemName: "doc")
                                .foregroundStyle(Color.Lumiere.textSecondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(url.lastPathComponent)
                                    .foregroundStyle(Color.Lumiere.textPrimary)
                                Text(url.deletingLastPathComponent().path)
                                    .font(.caption)
                                    .foregroundStyle(Color.Lumiere.textSecondary)
                            }
                        }
                        .padding(12)
                        .background(Color.Lumiere.surface.opacity(0.92))
                        .clipShape(.rect(cornerRadius: 14))
                    }
                }

                Button("Clear Recent Files") {
                    settingsStore.clearRecentFiles()
                }
                .buttonStyle(.bordered)
                .disabled(settingsStore.recentFiles.isEmpty)
            }
        }
    }

    private func settingsCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.Lumiere.textPrimary)
            content()
        }
        .padding(18)
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.Lumiere.textSecondary.opacity(0.16), lineWidth: 1)
        }
    }

    private func savePreset() {
        let name = newPresetName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        settingsStore.savePreset(
            ToolPreset(
                name: name,
                shadowIntensity: Float(newShadowIntensity),
                perspectiveSensitivity: Float(newPerspectiveSensitivity),
                annotationDefaults: ["tool": settingsStore.settings.toolPresets.first?.annotationDefaults["tool"] ?? AnnotationTool.arrow.rawValue]
            )
        )
        newPresetName = ""
    }

    private func syncFromStore() {
        selectedThemeRawValue = settingsStore.settings.themePreferenceRawValue
        autoCaptureEnabled = settingsStore.settings.autoCaptureEnabled
        selectedExportFormatRawValue = settingsStore.settings.defaultExportFormatRawValue
    }
}
