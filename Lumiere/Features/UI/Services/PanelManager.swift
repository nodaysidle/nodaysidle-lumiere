import AppKit
import SwiftUI

@MainActor
final class PanelManager: NSObject, ObservableObject {
    @Published private(set) var panelState: PanelState = .hidden

    private let logger = LumiereLogger.ui
    private let settingsStore: SettingsStore
    private let proximityThreshold: CGFloat = 100
    private let panelOriginDefaultsKey = "com.lumiere.app.panel-origin"
    private var panel: NSPanel?
    private var settingsPanel: NSPanel?
    private var mouseMonitor: Any?

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
    }

    func showPanel(at position: CGPoint) {
        ensurePanel()
        guard let panel else { return }

        let origin = resolvedOrigin(for: position)
        panel.setFrameOrigin(origin)
        persist(origin: origin)
        panel.orderFrontRegardless()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
            panelState = .revealing(progress: 0.4)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            self.panelState = .visible
        }
    }

    func hidePanel() {
        guard let panel, panelState != .hidden else { return }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
            panelState = .dismissing(progress: 0.4)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            self.panelState = .hidden
            panel.orderOut(nil)
        }
    }

    func updateProximity(cursorLocation: CGPoint) {
        guard let panel else { return }
        let targetFrame = panel.frame.insetBy(dx: -proximityThreshold, dy: -proximityThreshold)

        if targetFrame.contains(cursorLocation) {
            if panelState == .hidden {
                showPanel(at: panel.frame.origin)
            }
        } else if panelState.isVisible {
            hidePanel()
        }
    }

    func setPanelState(_ state: PanelState) {
        panelState = state
    }

    func presentSettings() {
        if let settingsPanel {
            settingsPanel.makeKeyAndOrderFront(nil)
            return
        }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.title = "Lumiere Settings"
        panel.center()
        panel.contentViewController = NSHostingController(
            rootView: SettingsView().environmentObject(settingsStore)
        )
        panel.orderFrontRegardless()
        settingsPanel = panel
    }

    private func ensurePanel() {
        guard panel == nil else { return }

        let controller = NSHostingController(
            rootView: GlassPanel(
                panelManager: self,
                onShadow: { NotificationCenter.default.post(name: .lumiereApplyShadow, object: nil) },
                onPerspective: { NotificationCenter.default.post(name: .lumiereApplyPerspective, object: nil) },
                onAnnotation: { NotificationCenter.default.post(name: .lumiereToggleAnnotation, object: nil) },
                onExport: { NotificationCenter.default.post(name: .lumiereExportImage, object: nil) },
                onCopy: { NotificationCenter.default.post(name: .lumiereCopyToClipboard, object: nil) },
                onClear: { NotificationCenter.default.post(name: .lumiereClearImage, object: nil) },
                onSettings: { [weak self] in self?.presentSettings() }
            )
        )

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 72),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.contentViewController = controller

        self.panel = panel
        installMouseMonitorIfNeeded()
    }

    private func installMouseMonitorIfNeeded() {
        guard mouseMonitor == nil else { return }

        mouseMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateProximity(cursorLocation: NSEvent.mouseLocation)
            }
        }
    }

    private func resolvedOrigin(for requestedOrigin: CGPoint) -> CGPoint {
        if requestedOrigin != .zero {
            return requestedOrigin
        }

        if let storedOrigin = restoredOrigin() {
            return storedOrigin
        }

        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            return CGPoint(x: 80, y: 80)
        }

        let frame = screen.visibleFrame
        return CGPoint(x: frame.midX - 210, y: frame.minY + 28)
    }

    private func restoredOrigin() -> CGPoint? {
        guard let value = UserDefaults.standard.string(forKey: panelOriginDefaultsKey) else {
            return nil
        }

        let components = value.split(separator: ",").compactMap { Double($0) }
        guard components.count == 2 else { return nil }
        return CGPoint(x: components[0], y: components[1])
    }

    private func persist(origin: CGPoint) {
        UserDefaults.standard.set("\(origin.x),\(origin.y)", forKey: panelOriginDefaultsKey)
        logger.debug("Stored panel origin at \(origin.x, format: .fixed(precision: 1)), \(origin.y, format: .fixed(precision: 1))")
    }
}
