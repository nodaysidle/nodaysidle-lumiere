import AppKit
import SwiftUI

struct ImageDisplayView: View {
    @Binding var image: NSImage?
    @Binding var annotations: [Annotation]
    @Binding var isAnnotateMode: Bool
    @Binding var activeTool: AnnotationTool

    let imageVersion: UUID
    let onShadow: () -> Void
    let onPerspective: () -> Void
    let onToggleAnnotation: () -> Void
    let onExport: () -> Void
    let onUndoAnnotation: () -> Void

    @State private var displayMode: DisplayMode = .fit
    @State private var baseScale: CGFloat = 1
    @State private var zoomScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var containerSize: CGSize = .zero
    @GestureState private var pinchScale: CGFloat = 1
    @GestureState private var dragTranslation: CGSize = .zero

    private let minimumZoomScale: CGFloat = 0.25
    private let maximumZoomScale: CGFloat = 8

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.Lumiere.background
                    .ignoresSafeArea()

                if let image {
                    interactiveImageView(for: image)
                        .id(imageVersion)
                } else {
                    emptyStateView
                }

                if image != nil && isAnnotateMode {
                    VStack {
                        annotationToolbar
                            .padding(.top, 22)
                        Spacer()
                    }
                }

                VStack {
                    Spacer()
                    bottomToolbar
                        .padding(.bottom, 18)
                }
            }
            .onAppear {
                containerSize = proxy.size
                syncDisplayState(resetZoom: true)
            }
            .onChange(of: proxy.size) { _, newSize in
                containerSize = newSize
                syncDisplayState(resetZoom: false)
            }
            .onChange(of: imageVersion) { _, _ in
                displayMode = .fit
                syncDisplayState(resetZoom: true)
            }
            .onChange(of: displayMode) { _, _ in
                syncDisplayState(resetZoom: true)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 46, weight: .medium))
                .foregroundStyle(Color.Lumiere.textSecondary)

            Text("No Image Yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.Lumiere.textPrimary)

            Text("Capture from the clipboard or paste an image to start polishing.")
                .font(.callout)
                .foregroundStyle(Color.Lumiere.textSecondary)
        }
    }

    private var annotationToolbar: some View {
        HStack(spacing: 8) {
            ForEach(AnnotationTool.allCases) { tool in
                annotationToolButton(tool)
            }

            Divider()
                .frame(height: 24)
                .overlay(Color.Lumiere.textSecondary.opacity(0.2))

            Button(action: onUndoAnnotation) {
                Label("Undo", systemImage: "arrow.uturn.backward")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.Lumiere.textSecondary)
                    .frame(width: 34, height: 34)
                    .background(Color.Lumiere.surface.opacity(0.92))
                    .clipShape(.circle)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("z", modifiers: .command)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.Lumiere.textSecondary.opacity(0.18), lineWidth: 1)
        }
    }

    private func annotationToolButton(_ tool: AnnotationTool) -> some View {
        Button {
            activeTool = tool
        } label: {
            Image(systemName: tool.symbolName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(activeTool == tool ? Color.Lumiere.background : Color.Lumiere.accent)
                .frame(width: 34, height: 34)
                .background(activeTool == tool ? Color.Lumiere.accent : Color.Lumiere.surface.opacity(0.92))
                .clipShape(.circle)
        }
        .buttonStyle(.plain)
    }

    private var bottomToolbar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                zoomButton(symbol: "minus.magnifyingglass") { zoomBy(factor: 0.9) }

                Text(baseScale * zoomScale * pinchScale, format: .percent.precision(.fractionLength(0)))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Color.Lumiere.textSecondary)
                    .frame(minWidth: 54)

                zoomButton(symbol: "plus.magnifyingglass") { zoomBy(factor: 1.1) }

                modeButton(symbol: "arrow.up.left.and.arrow.down.right", isActive: displayMode == .fit) {
                    displayMode = .fit
                }

                modeButton(symbol: "1.square", isActive: displayMode == .actualSize) {
                    displayMode = .actualSize
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.Lumiere.surface.opacity(0.94))
            .clipShape(.capsule)

            HStack(spacing: 8) {
                ActionButton(symbol: "sun.max", label: "Shadow", action: onShadow, isEnabled: image != nil)
                ActionButton(symbol: "perspective", label: "Perspective", action: onPerspective, isEnabled: image != nil)
                ActionButton(
                    symbol: isAnnotateMode ? "pencil.circle.fill" : "pencil",
                    label: "Annotate",
                    action: onToggleAnnotation,
                    isActive: isAnnotateMode,
                    isEnabled: image != nil,
                    shortcut: "a",
                    modifiers: [.command, .shift]
                )
                ActionButton(
                    symbol: "square.and.arrow.up",
                    label: "Export",
                    action: onExport,
                    isEnabled: image != nil,
                    shortcut: "e",
                    modifiers: .command
                )
            }
        }
    }

    private func zoomButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .foregroundStyle(image == nil ? Color.Lumiere.textSecondary.opacity(0.4) : Color.Lumiere.textSecondary)
        }
        .buttonStyle(.plain)
        .disabled(image == nil)
    }

    private func modeButton(symbol: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .foregroundStyle(isActive ? Color.Lumiere.background : Color.Lumiere.textSecondary)
                .frame(width: 32, height: 32)
                .background(isActive ? Color.Lumiere.accent : Color.Lumiere.surface.opacity(0.9))
                .clipShape(.rect(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(image == nil)
        .opacity(image == nil ? 0.45 : 1)
    }

    private var currentOffset: CGSize {
        CGSize(width: offset.width + dragTranslation.width, height: offset.height + dragTranslation.height)
    }

    private func interactiveImageView(for image: NSImage) -> some View {
        imageCanvas(for: image)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .scaleEffect(zoomScale * pinchScale)
            .offset(currentOffset)
            .gesture(isAnnotateMode ? nil : panGesture)
            .simultaneousGesture(isAnnotateMode ? nil : magnificationGesture)
            .animation(.easeInOut(duration: 0.18), value: imageVersion)
    }

    private func imageCanvas(for image: NSImage) -> some View {
        ZStack {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .scaledToFit()

            DrawingLayer(
                annotations: $annotations,
                activeTool: $activeTool,
                isEnabled: isAnnotateMode
            )
        }
        .frame(width: displayedSize(for: image).width, height: displayedSize(for: image).height)
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.Lumiere.textSecondary.opacity(0.15), lineWidth: 1)
        }
        .clipShape(.rect(cornerRadius: 24))
        .shadow(color: Color.Lumiere.background.opacity(0.45), radius: 24, x: 0, y: 12)
    }

    private var panGesture: some Gesture {
        DragGesture()
            .updating($dragTranslation) { value, state, _ in
                state = value.translation
            }
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .updating($pinchScale) { value, state, _ in
                state = value
            }
            .onEnded { value in
                zoomBy(factor: value)
            }
    }

    private func syncDisplayState(resetZoom: Bool) {
        guard let image else {
            baseScale = 1
            zoomScale = 1
            offset = .zero
            lastOffset = .zero
            return
        }

        baseScale = resolvedBaseScale(for: image, in: containerSize)
        if resetZoom {
            zoomScale = 1
            offset = .zero
            lastOffset = .zero
        }
    }

    private func resolvedBaseScale(for image: NSImage, in size: CGSize) -> CGFloat {
        guard size.width > 0, size.height > 0, image.size.width > 0, image.size.height > 0 else {
            return 1
        }

        switch displayMode {
        case .fit:
            return min(size.width / image.size.width, size.height / image.size.height)
        case .actualSize:
            return 1
        }
    }

    private func displayedSize(for image: NSImage) -> CGSize {
        CGSize(width: image.size.width * baseScale, height: image.size.height * baseScale)
    }

    private func zoomBy(factor: CGFloat) {
        guard image != nil else { return }
        zoomScale = min(maximumZoomScale, max(minimumZoomScale, zoomScale * factor))
    }
}

private struct ActionButton: View {
    let symbol: String
    let label: String
    let action: () -> Void
    var isActive: Bool = false
    var isEnabled: Bool = true
    var shortcut: KeyEquivalent? = nil
    var modifiers: EventModifiers = []

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .semibold))
                Text(label)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(isActive ? Color.Lumiere.background : Color.Lumiere.accent)
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(isActive ? Color.Lumiere.accent : Color.Lumiere.surface.opacity(0.94))
            .clipShape(.capsule)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .applyKeyboardShortcut(shortcut, modifiers: modifiers)
    }
}

private enum DisplayMode {
    case fit
    case actualSize
}

private extension View {
    @ViewBuilder
    func applyKeyboardShortcut(_ shortcut: KeyEquivalent?, modifiers: EventModifiers = []) -> some View {
        if let shortcut {
            keyboardShortcut(shortcut, modifiers: modifiers)
        } else {
            self
        }
    }
}
