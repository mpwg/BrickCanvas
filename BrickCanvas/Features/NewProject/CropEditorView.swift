import CoreGraphics
import SwiftUI

enum CropAspectPreset: String, CaseIterable, Identifiable {
    case square
    case fourByFive
    case landscape
    case original

    var id: Self { self }

    var title: String {
        switch self {
        case .square:
            "Quadrat"
        case .fourByFive:
            "4:5"
        case .landscape:
            "16:9"
        case .original:
            "Original"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .square:
            "Quadratischer Zuschnitt"
        case .fourByFive:
            "Hochformat 4 zu 5"
        case .landscape:
            "Querformat 16 zu 9"
        case .original:
            "Originales Seitenverhältnis"
        }
    }

    func aspectRatio(for imageSize: CGSize) -> CGFloat {
        switch self {
        case .square:
            1
        case .fourByFive:
            4 / 5
        case .landscape:
            16 / 9
        case .original:
            max(imageSize.width, 1) / max(imageSize.height, 1)
        }
    }
}

struct CropEditorView: View {
    let image: CGImage
    let aspectPreset: CropAspectPreset
    let onCropChange: (CropLayout) -> Void

    @State private var zoomScale: CGFloat = 1
    @State private var committedZoomScale: CGFloat = 1
    @State private var contentOffset: CGSize = .zero
    @State private var committedContentOffset: CGSize = .zero
    @State private var viewportSize: CGSize = .zero
    @State private var lastNormalizedCenter: CGPoint = CGPoint(x: 0.5, y: 0.5)

    private let cropService = DefaultImageCropService()
    private let maximumZoomScale: CGFloat = 4

    var body: some View {
        let imageSize = CGSize(width: image.width, height: image.height)

        Color.clear
            .overlay {
                GeometryReader { proxy in
                    let size = proxy.size
                    let cropFrame = cropFrame(in: size, imageSize: imageSize)
                    let layout = cropService.layout(
                        imageSize: imageSize,
                        canvasSize: size,
                        cropFrame: cropFrame,
                        zoomScale: zoomScale,
                        proposedOffset: contentOffset
                    )
                    let imageRect = CGRect(
                        x: (size.width - layout.imageDisplaySize.width) / 2 + layout.constrainedOffset.width,
                        y: (size.height - layout.imageDisplaySize.height) / 2 + layout.constrainedOffset.height,
                        width: layout.imageDisplaySize.width,
                        height: layout.imageDisplaySize.height
                    )

                    ZStack {
                        Color.black.opacity(0.92)

                        Image(decorative: image, scale: 1)
                            .resizable()
                            .frame(
                                width: layout.imageDisplaySize.width,
                                height: layout.imageDisplaySize.height
                            )
                            .position(x: imageRect.midX, y: imageRect.midY)

                        CropScrimShape(cropFrame: layout.cropFrame, cornerRadius: 28)
                            .fill(.black.opacity(0.42), style: FillStyle(eoFill: true))

                        CropOverlayShape(cropFrame: layout.cropFrame)
                            .stroke(.white.opacity(0.95), lineWidth: 2)

                        CropGridOverlay(cropFrame: layout.cropFrame)
                            .stroke(.white.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [6, 6]))

                        VStack {
                            HStack {
                                Label("\(Int(zoomScale * 100)) %", systemImage: "plus.magnifyingglass")
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(.black.opacity(0.45), in: Capsule())

                                Spacer()
                            }

                            Spacer()
                        }
                        .padding(16)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .contentShape(Rectangle())
                    .onAppear {
                        viewportSize = size
                        lastNormalizedCenter = normalizedCenter(from: layout.cropRegion)
                        publish(layout)
                    }
                    .onChange(of: size) { _, newSize in
                        preserveCenterAndApply(for: newSize)
                    }
                    .onChange(of: aspectPreset) { _, _ in
                        preserveCenterAndApply(for: viewportSize)
                    }
                    .onChange(of: image.width) { _, _ in
                        resetEditor()
                    }
                    .simultaneousGesture(dragGesture)
                    .simultaneousGesture(magnifyGesture)
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Framing-Editor")
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let proposedOffset = CGSize(
                    width: committedContentOffset.width + value.translation.width,
                    height: committedContentOffset.height + value.translation.height
                )
                let layout = cropService.layout(
                    imageSize: CGSize(width: image.width, height: image.height),
                    canvasSize: viewportSize,
                    cropFrame: cropFrame(in: viewportSize, imageSize: CGSize(width: image.width, height: image.height)),
                    zoomScale: zoomScale,
                    proposedOffset: proposedOffset
                )
                contentOffset = layout.constrainedOffset
                lastNormalizedCenter = normalizedCenter(from: layout.cropRegion)
                publish(layout)
            }
            .onEnded { _ in
                committedContentOffset = contentOffset
            }
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let proposedZoomScale = (committedZoomScale * value.magnification).clamped(to: 1...maximumZoomScale)
                let layout = cropService.layout(
                    imageSize: CGSize(width: image.width, height: image.height),
                    canvasSize: viewportSize,
                    cropFrame: cropFrame(in: viewportSize, imageSize: CGSize(width: image.width, height: image.height)),
                    zoomScale: proposedZoomScale,
                    proposedOffset: contentOffset
                )
                zoomScale = proposedZoomScale
                contentOffset = layout.constrainedOffset
                lastNormalizedCenter = normalizedCenter(from: layout.cropRegion)
                publish(layout)
            }
            .onEnded { _ in
                committedZoomScale = zoomScale
                committedContentOffset = contentOffset
            }
    }

    private func applyConstraints() {
        let layout = cropService.layout(
            imageSize: CGSize(width: image.width, height: image.height),
            canvasSize: viewportSize,
            cropFrame: cropFrame(in: viewportSize, imageSize: CGSize(width: image.width, height: image.height)),
            zoomScale: zoomScale,
            proposedOffset: contentOffset
        )
        contentOffset = layout.constrainedOffset
        committedContentOffset = layout.constrainedOffset
        lastNormalizedCenter = normalizedCenter(from: layout.cropRegion)
        publish(layout)
    }

    private func preserveCenterAndApply(for newViewportSize: CGSize) {
        let imageSize = CGSize(width: image.width, height: image.height)
        viewportSize = newViewportSize

        let proposedOffset = cropService.offset(
            preservingNormalizedCenter: lastNormalizedCenter,
            imageSize: imageSize,
            canvasSize: newViewportSize,
            cropFrame: cropFrame(in: newViewportSize, imageSize: imageSize),
            zoomScale: zoomScale
        )
        let layout = cropService.layout(
            imageSize: imageSize,
            canvasSize: newViewportSize,
            cropFrame: cropFrame(in: newViewportSize, imageSize: imageSize),
            zoomScale: zoomScale,
            proposedOffset: proposedOffset
        )
        contentOffset = layout.constrainedOffset
        committedContentOffset = layout.constrainedOffset
        lastNormalizedCenter = normalizedCenter(from: layout.cropRegion)
        publish(layout)
    }

    private func publish(_ layout: CropLayout) {
        onCropChange(layout)
    }

    private func resetEditor() {
        zoomScale = 1
        committedZoomScale = 1
        contentOffset = .zero
        committedContentOffset = .zero
        lastNormalizedCenter = CGPoint(x: 0.5, y: 0.5)
        applyConstraints()
    }

    private func normalizedCenter(from cropRegion: CropRegion) -> CGPoint {
        CGPoint(
            x: cropRegion.originX + cropRegion.width / 2,
            y: cropRegion.originY + cropRegion.height / 2
        )
    }

    private func cropFrame(in canvasSize: CGSize, imageSize: CGSize) -> CGRect {
        let horizontalInset = max(canvasSize.width * 0.10, 24)
        let verticalInset = max(canvasSize.height * 0.10, 24)
        let availableWidth = max(canvasSize.width - horizontalInset * 2, 120)
        let availableHeight = max(canvasSize.height - verticalInset * 2, 120)
        let targetRatio = aspectPreset.aspectRatio(for: imageSize)

        let frameSize: CGSize
        if availableWidth / availableHeight > targetRatio {
            frameSize = CGSize(width: availableHeight * targetRatio, height: availableHeight)
        } else {
            frameSize = CGSize(width: availableWidth, height: availableWidth / targetRatio)
        }

        return CGRect(
            x: (canvasSize.width - frameSize.width) / 2,
            y: (canvasSize.height - frameSize.height) / 2,
            width: frameSize.width,
            height: frameSize.height
        )
    }
}

private struct CropOverlayShape: Shape {
    let cropFrame: CGRect

    func path(in rect: CGRect) -> Path {
        Path(roundedRect: cropFrame, cornerRadius: 28)
    }
}

private struct CropGridOverlay: Shape {
    let cropFrame: CGRect

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(in: cropFrame, cornerSize: CGSize(width: 28, height: 28))
        let verticalStep = cropFrame.width / 3
        let horizontalStep = cropFrame.height / 3

        for index in 1...2 {
            let x = cropFrame.minX + verticalStep * CGFloat(index)
            path.move(to: CGPoint(x: x, y: cropFrame.minY))
            path.addLine(to: CGPoint(x: x, y: cropFrame.maxY))

            let y = cropFrame.minY + horizontalStep * CGFloat(index)
            path.move(to: CGPoint(x: cropFrame.minX, y: y))
            path.addLine(to: CGPoint(x: cropFrame.maxX, y: y))
        }

        return path
    }
}

private struct CropScrimShape: Shape {
    let cropFrame: CGRect
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        path.addRoundedRect(in: cropFrame, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        return path
    }
}

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
