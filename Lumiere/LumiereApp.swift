import SwiftUI

@main
struct LumiereApp: App {
    @StateObject private var settingsStore: SettingsStore
    @StateObject private var viewModel: MainViewModel
    @StateObject private var panelManager: PanelManager

    init() {
        let settingsStore = SettingsStore()
        _settingsStore = StateObject(wrappedValue: settingsStore)
        _viewModel = StateObject(wrappedValue: MainViewModel(settingsStore: settingsStore))
        _panelManager = StateObject(wrappedValue: PanelManager(settingsStore: settingsStore))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .environmentObject(settingsStore)
                .task {
                    panelManager.showPanel(at: .zero)
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {}

            CommandMenu("Lumiere") {
                Button("Capture from Clipboard") {
                    NotificationCenter.default.post(name: .lumiereCaptureClipboard, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])

                Button("Apply Shadow") {
                    NotificationCenter.default.post(name: .lumiereApplyShadow, object: nil)
                }

                Button("Correct Perspective") {
                    NotificationCenter.default.post(name: .lumiereApplyPerspective, object: nil)
                }

                Divider()

                Button("Arrow Tool") {
                    NotificationCenter.default.post(name: .lumiereUseArrowTool, object: nil)
                }
                .keyboardShortcut("a", modifiers: [.command, .shift])

                Button("Text Tool") {
                    NotificationCenter.default.post(name: .lumiereUseTextTool, object: nil)
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])

                Button("Rectangle Tool") {
                    NotificationCenter.default.post(name: .lumiereUseRectangleTool, object: nil)
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])

                Button("Blur Tool") {
                    NotificationCenter.default.post(name: .lumiereUseBlurTool, object: nil)
                }
                .keyboardShortcut("b", modifiers: [.command, .shift])

                Button("Undo Annotation") {
                    NotificationCenter.default.post(name: .lumiereUndoAnnotation, object: nil)
                }
                .keyboardShortcut("z", modifiers: .command)

                Divider()

                Button("Export") {
                    NotificationCenter.default.post(name: .lumiereExportImage, object: nil)
                }
                .keyboardShortcut("e", modifiers: .command)

                Button("Settings") {
                    panelManager.presentSettings()
                }
                .keyboardShortcut(",", modifiers: .command)
            }

            CommandGroup(after: .appInfo) {
                Button("Settings") {
                    panelManager.presentSettings()
                }
                .keyboardShortcut(",", modifiers: .command)

                Button("Quit Lumiere") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            }
        }
    }
}
