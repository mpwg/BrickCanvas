import CoreGraphics
import SwiftUI

struct MosaicPreviewView: View {
    let grid: MosaicGrid
    let palette: [BrickColor]

    @State private var rasterizedImage: CGImage?
    @State private var steadyZoomScale = 1.0
    @State private var contentOffset: CGSize = .zero
    @GestureState private var gestureZoomScale = 1.0
    @GestureState private var dragTranslation: CGSize = .zero

    private let minimumZoomScale = 1.0
    private let maximumZoomScale = 8.0
    private let gridLineThreshold = 14.0

    var body: some View {
        GeometryReader { proxy in
            let containerSize = proxy.size
            let layout = layout(for: containerSize)

            ZStack {
                Color(.tertiarySystemGroupedBackground)

                if let rasterizedImage {
                    Image(decorative: rasterizedImage, scale: 1)
                        .resizable()
                        .interpolation(.none)
                        .frame(width: layout.contentSize.width, height: layout.contentSize.height)
                        .offset(x: layout.offset.width, y: layout.offset.height)
                } else {
                    ProgressView()
                        .controlSize(.large)
                }

                if layout.cellLength >= gridLineThreshold {
                    Canvas { context, size in
                        drawGridLines(in: context, size: size, layout: layout)
                    }
                    .allowsHitTesting(false)
                }
            }
            .contentShape(Rectangle())
            .gesture(doubleTapGesture(containerSize: containerSize))
            .simultaneousGesture(dragGesture(containerSize: containerSize))
            .simultaneousGesture(magnifyGesture(containerSize: containerSize))
            .task(id: rasterizationKey) {
                await rasterizePreviewIfNeeded()
            }
            .accessibilityLabel("Mosaikvorschau")
            .accessibilityHint("Mit zwei Fingern zoomen und ziehen, um das Raster zu prüfen.")
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(alignment: .topTrailing) {
            previewControls
                .padding(14)
        }
    }

    private var previewControls: some View {
        HStack(spacing: 8) {
            Button {
                adjustZoom(by: 0.75)
            } label: {
                Image(systemName: "minus")
            }

            Button {
                resetViewport()
            } label: {
                Image(systemName: "arrow.counterclockwise")
            }

            Button {
                adjustZoom(by: 1.25)
            } label: {
                Image(systemName: "plus")
            }
        }
        .buttonStyle(.bordered)
        .labelStyle(.iconOnly)
        .font(.subheadline.weight(.semibold))
    }

    private var rasterizationKey: MosaicPreviewRasterizationKey {
        MosaicPreviewRasterizationKey(grid: grid, palette: palette)
    }

    private func layout(for containerSize: CGSize) -> MosaicPreviewLayout {
        let columnCount = CGFloat(grid.size.width)
        let rowCount = CGFloat(grid.size.height)
        let baseCellLength = min(
            containerSize.width / max(columnCount, 1),
            containerSize.height / max(rowCount, 1)
        )
        let zoomScale = CGFloat(clampedZoomScale(steadyZoomScale * gestureZoomScale))
        let cellLength = baseCellLength * zoomScale
        let contentSize = CGSize(
            width: columnCount * cellLength,
            height: rowCount * cellLength
        )
        let clampedOffset = clamp(
            CGSize(
                width: contentOffset.width + dragTranslation.width,
                height: contentOffset.height + dragTranslation.height
            ),
            for: containerSize,
            contentSize: contentSize
        )

        return MosaicPreviewLayout(
            contentSize: contentSize,
            offset: clampedOffset,
            cellLength: cellLength,
            zoomScale: zoomScale
        )
    }

    private func drawGridLines(in context: GraphicsContext, size: CGSize, layout: MosaicPreviewLayout) {
        let origin = CGPoint(
            x: (size.width - layout.contentSize.width) / 2 + layout.offset.width,
            y: (size.height - layout.contentSize.height) / 2 + layout.offset.height
        )
        let strokeStyle = StrokeStyle(lineWidth: max(1 / layout.zoomScale, 0.5))
        let borderRect = CGRect(origin: origin, size: layout.contentSize)
        let lineColor = Color.black.opacity(0.18)

        context.stroke(Path(borderRect), with: .color(lineColor), style: strokeStyle)

        for column in 1..<grid.size.width {
            let x = origin.x + (CGFloat(column) * layout.cellLength)
            var path = Path()
            path.move(to: CGPoint(x: x, y: origin.y))
            path.addLine(to: CGPoint(x: x, y: origin.y + layout.contentSize.height))
            context.stroke(path, with: .color(lineColor), style: strokeStyle)
        }

        for row in 1..<grid.size.height {
            let y = origin.y + (CGFloat(row) * layout.cellLength)
            var path = Path()
            path.move(to: CGPoint(x: origin.x, y: y))
            path.addLine(to: CGPoint(x: origin.x + layout.contentSize.width, y: y))
            context.stroke(path, with: .color(lineColor), style: strokeStyle)
        }
    }

    private func dragGesture(containerSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($dragTranslation) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                let contentSize = layout(for: containerSize).contentSize
                contentOffset = clamp(
                    CGSize(
                        width: contentOffset.width + value.translation.width,
                        height: contentOffset.height + value.translation.height
                    ),
                    for: containerSize,
                    contentSize: contentSize
                )
            }
    }

    private func magnifyGesture(containerSize: CGSize) -> some Gesture {
        MagnifyGesture()
            .updating($gestureZoomScale) { value, state, _ in
                state = value.magnification
            }
            .onEnded { value in
                steadyZoomScale = clampedZoomScale(steadyZoomScale * value.magnification)
                let contentSize = layout(for: containerSize).contentSize
                contentOffset = clamp(contentOffset, for: containerSize, contentSize: contentSize)
            }
    }

    private func doubleTapGesture(containerSize: CGSize) -> some Gesture {
        SpatialTapGesture(count: 2)
            .onEnded { _ in
                if steadyZoomScale > minimumZoomScale {
                    resetViewport()
                    return
                }

                steadyZoomScale = 2
                let contentSize = layout(for: containerSize).contentSize
                contentOffset = clamp(contentOffset, for: containerSize, contentSize: contentSize)
            }
    }

    private func adjustZoom(by factor: Double) {
        steadyZoomScale = clampedZoomScale(steadyZoomScale * factor)
        contentOffset = .zero
    }

    private func resetViewport() {
        steadyZoomScale = minimumZoomScale
        contentOffset = .zero
    }

    private func clampedZoomScale(_ value: Double) -> Double {
        min(max(value, minimumZoomScale), maximumZoomScale)
    }

    private func clamp(_ offset: CGSize, for containerSize: CGSize, contentSize: CGSize) -> CGSize {
        let horizontalLimit = max((contentSize.width - containerSize.width) / 2, 0)
        let verticalLimit = max((contentSize.height - containerSize.height) / 2, 0)

        return CGSize(
            width: min(max(offset.width, -horizontalLimit), horizontalLimit),
            height: min(max(offset.height, -verticalLimit), verticalLimit)
        )
    }

    @MainActor
    private func rasterizePreviewIfNeeded() async {
        do {
            let image = try await Task.detached(priority: .userInitiated) {
                try MosaicPreviewRasterizer.makeImage(grid: grid, palette: palette)
            }.value
            rasterizedImage = image
        } catch {
            rasterizedImage = nil
        }
    }
}

private struct MosaicPreviewLayout {
    let contentSize: CGSize
    let offset: CGSize
    let cellLength: CGFloat
    let zoomScale: CGFloat
}

private struct MosaicPreviewRasterizationKey: Hashable {
    let grid: MosaicGrid
    let palette: [BrickColor]
}

private enum MosaicPreviewRasterizer {
    static func makeImage(grid: MosaicGrid, palette: [BrickColor]) throws -> CGImage {
        let width = grid.size.width
        let height = grid.size.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let pixelCount = width * height
        var bytes = [UInt8](repeating: 0, count: pixelCount * bytesPerPixel)
        let rgbByColorID = Dictionary(uniqueKeysWithValues: palette.map { ($0.id, $0.rgb) })

        for cell in grid.cells {
            let pixelIndex = ((cell.coordinate.y * width) + cell.coordinate.x) * bytesPerPixel
            let rgb = rgbByColorID[cell.colorID] ?? RGBColor(red: 142, green: 142, blue: 147)
            bytes[pixelIndex] = rgb.red
            bytes[pixelIndex + 1] = rgb.green
            bytes[pixelIndex + 2] = rgb.blue
            bytes[pixelIndex + 3] = 255
        }

        guard let provider = CGDataProvider(data: Data(bytes) as CFData),
              let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let image = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
              ) else {
            throw ServiceError.processingFailed("Die Mosaikvorschau konnte nicht gerastert werden.")
        }

        return image
    }
}

#Preview("Mosaikvorschau") {
    MosaicPreviewView(
        grid: DomainFixtures.grid,
        palette: DomainFixtures.palette
    )
    .frame(height: 340)
    .padding()
}
