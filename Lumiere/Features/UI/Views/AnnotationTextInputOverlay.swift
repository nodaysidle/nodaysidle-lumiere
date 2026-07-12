import SwiftUI

struct AnnotationTextInputOverlay: View {
    let position: CGPoint
    let onSubmit: (String) -> Void
    let onCancel: () -> Void

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 6) {
            TextField("Enter text", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.Lumiere.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(width: 180)
                .background(Color.Lumiere.surface)
                .clipShape(.rect(cornerRadius: 8))
                .focused($isFocused)
                .onSubmit {
                    commitOrCancel()
                }
                .onKeyPress(.escape) {
                    onCancel()
                    return .handled
                }

            HStack(spacing: 8) {
                Button("Cancel") { onCancel() }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(Color.Lumiere.textSecondary)

                Button("Done") {
                    commitOrCancel()
                }
                .buttonStyle(.plain)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.Lumiere.accent)
            }
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 12))
        .position(position)
        .onAppear {
            isFocused = true
        }
    }

    private func commitOrCancel() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            onSubmit(trimmed)
        } else {
            onCancel()
        }
    }
}
