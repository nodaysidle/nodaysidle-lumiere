import SwiftUI

struct GlassPanel: View {
    @ObservedObject var panelManager: PanelManager

    let onShadow: () -> Void
    let onPerspective: () -> Void
    let onAnnotation: () -> Void
    let onExport: () -> Void
    let onCopy: () -> Void
    let onClear: () -> Void
    let onSettings: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            toolButton(symbol: "sun.max", action: onShadow)
            toolButton(symbol: "perspective", action: onPerspective)
            toolButton(symbol: "pencil", action: onAnnotation)

            Divider()
                .frame(height: 26)
                .overlay(Color.Lumiere.textSecondary.opacity(0.25))

            toolButton(symbol: "doc.on.doc", action: onCopy)
            toolButton(symbol: "trash", action: onClear, tint: Color.Lumiere.error)

            Spacer(minLength: 0)

            toolButton(symbol: "square.and.arrow.up", action: onExport)
            toolButton(symbol: "gearshape", action: onSettings, tint: Color.Lumiere.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(width: 420, height: 72)
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.Lumiere.textSecondary.opacity(0.22), lineWidth: 1)
        }
        .shadow(color: Color.Lumiere.background.opacity(0.45), radius: 24, x: 0, y: 14)
        .opacity(panelManager.panelState.progress)
        .scaleEffect(0.94 + (panelManager.panelState.progress * 0.06))
    }

    private func toolButton(symbol: String, action: @escaping () -> Void, tint: Color = Color.Lumiere.accent) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(Color.Lumiere.surface.opacity(0.92))
                .clipShape(.circle)
                .overlay {
                    Circle()
                        .stroke(Color.Lumiere.textSecondary.opacity(0.15), lineWidth: 0.8)
                }
        }
        .buttonStyle(.plain)
    }
}
