import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        ZStack {
            Color.Lumiere.background
                .ignoresSafeArea()

            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.18)
                .ignoresSafeArea()

            ImageDisplayView(
                image: $viewModel.currentImage,
                annotations: $viewModel.annotations,
                isAnnotateMode: $viewModel.isAnnotateMode,
                activeTool: $viewModel.activeTool,
                imageVersion: viewModel.imageVersion,
                onShadow: viewModel.processShadow,
                onPerspective: viewModel.processPerspective,
                onToggleAnnotation: viewModel.toggleAnnotationMode,
                onExport: viewModel.exportImage,
                onUndoAnnotation: viewModel.undoLastAnnotation
            )
            .padding(14)

            VStack {
                if let statusMessage = viewModel.statusMessage {
                    Text(statusMessage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.Lumiere.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(.capsule)
                        .overlay {
                            Capsule()
                                .stroke(Color.Lumiere.textSecondary.opacity(0.18), lineWidth: 1)
                        }
                        .padding(.top, 20)
                }

                Spacer()
            }

            if viewModel.isProcessing || viewModel.isExporting {
                ZStack {
                    Color.Lumiere.background.opacity(0.35)
                        .ignoresSafeArea()

                    VStack(spacing: 12) {
                        ProgressView()
                            .controlSize(.large)
                            .tint(Color.Lumiere.accent)
                        Text(viewModel.isExporting ? "Exporting" : "Processing")
                            .foregroundStyle(Color.Lumiere.textPrimary)
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 24)
                    .background(.ultraThinMaterial)
                    .clipShape(.rect(cornerRadius: 22))
                }
            }
        }
        .frame(minWidth: 720, minHeight: 520)
        .onPasteCommand(of: [.png, .jpeg, .fileURL, .tiff]) { providers in
            for provider in providers where provider.canLoadObject(ofClass: NSImage.self) {
                _ = provider.loadObject(ofClass: NSImage.self) { image, _ in
                    guard let image = image as? NSImage,
                        let imageData = image.tiffRepresentation
                    else { return }

                    Task { @MainActor in
                        guard let pastedImage = NSImage(data: imageData) else { return }
                        viewModel.ingestImage(pastedImage, sourceLabel: "Paste")
                    }
                }
                return
            }
        }
    }
}
