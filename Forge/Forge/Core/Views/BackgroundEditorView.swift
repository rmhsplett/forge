import SwiftUI
import UIKit

/// Wrapper so a picked UIImage can drive a `.fullScreenCover(item:)`.
struct PickedImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

/// Lets the user frame a background photo: drag to move, pinch to zoom over a
/// screen-shaped preview. On "Use", the framed region is rendered to an image
/// and handed back via `onSave`, so what's shown is exactly what gets saved.
struct BackgroundEditorView: View {

    let image: UIImage
    let onSave: (Data) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var frameSize: CGSize = .zero

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                composition(in: geo.size)
                    .contentShape(Rectangle())
                    .gesture(dragGesture(in: geo.size).simultaneously(with: magnifyGesture(in: geo.size)))
                    .onAppear { frameSize = geo.size }
            }
            .background(Color.black)
            .ignoresSafeArea()
            .overlay(alignment: .bottom) {
                Text("Drag to move · pinch to zoom")
                    .font(.footnote)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 90)
            }
            .navigationTitle("Position photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Use") { save() } }
            }
        }
        .preferredColorScheme(.dark)
    }

    /// The framed image: fill the preview, then apply zoom + pan, then clip.
    private func composition(in size: CGSize) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: size.width, height: size.height)
            .scaleEffect(scale)
            .offset(offset)
            .frame(width: size.width, height: size.height)
            .clipped()
    }

    private func magnifyGesture(in size: CGSize) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = max(1, min(lastScale * value, 5))
                offset = clamp(offset, in: size)
            }
            .onEnded { _ in
                lastScale = scale
                lastOffset = offset
            }
    }

    private func dragGesture(in size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let proposed = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
                offset = clamp(proposed, in: size)
            }
            .onEnded { _ in lastOffset = offset }
    }

    /// Keep the image covering the preview so no black edges show.
    private func clamp(_ proposed: CGSize, in size: CGSize) -> CGSize {
        let display = displayedImageSize(in: size)
        let maxX = max(0, (display.width - size.width) / 2)
        let maxY = max(0, (display.height - size.height) / 2)
        return CGSize(
            width: min(max(proposed.width, -maxX), maxX),
            height: min(max(proposed.height, -maxY), maxY)
        )
    }

    private func displayedImageSize(in size: CGSize) -> CGSize {
        guard image.size.height > 0, size.height > 0 else { return size }
        let imageAspect = image.size.width / image.size.height
        let frameAspect = size.width / size.height
        let fill: CGSize
        if imageAspect > frameAspect {
            fill = CGSize(width: size.height * imageAspect, height: size.height)
        } else {
            fill = CGSize(width: size.width, height: size.width / imageAspect)
        }
        return CGSize(width: fill.width * scale, height: fill.height * scale)
    }

    @MainActor private func save() {
        let size = frameSize == .zero ? UIScreen.main.bounds.size : frameSize
        let renderer = ImageRenderer(content: composition(in: size))
        renderer.scale = displayScale
        if let rendered = renderer.uiImage,
           let data = rendered.jpegData(compressionQuality: 0.9) {
            onSave(data)
        }
        dismiss()
    }
}
