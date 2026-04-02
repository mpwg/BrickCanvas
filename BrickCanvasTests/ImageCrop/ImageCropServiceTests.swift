import CoreGraphics
import Testing
@testable import BrickCanvas

struct ImageCropServiceTests {
    private let service = DefaultImageCropService()

    @Test
    func squareViewportProducesCenteredCropByDefault() {
        let layout = service.layout(
            imageSize: CGSize(width: 4000, height: 3000),
            canvasSize: CGSize(width: 300, height: 300),
            cropFrame: CGRect(x: 0, y: 0, width: 300, height: 300),
            zoomScale: 1,
            proposedOffset: .zero
        )

        #expect(layout.constrainedOffset == .zero)
        #expect(layout.cropRegion.originX == 0.125)
        #expect(layout.cropRegion.originY == 0)
        #expect(layout.cropRegion.width == 0.75)
        #expect(layout.cropRegion.height == 1)
    }

    @Test
    func layoutClampsOverscrollToImageBounds() {
        let layout = service.layout(
            imageSize: CGSize(width: 4000, height: 3000),
            canvasSize: CGSize(width: 300, height: 300),
            cropFrame: CGRect(x: 0, y: 0, width: 300, height: 300),
            zoomScale: 1,
            proposedOffset: CGSize(width: 500, height: -500)
        )

        #expect(layout.constrainedOffset.width == 50)
        #expect(layout.constrainedOffset.height == 0)
        #expect(layout.cropRegion.originX == 0)
        #expect(layout.cropRegion.originY == 0)
    }

    @Test
    func croppedImageRespectsNormalizedRegion() throws {
        let image = try makeImage(size: CGSize(width: 100, height: 80))
        let region = CropRegion(originX: 0.25, originY: 0.125, width: 0.5, height: 0.5)

        let croppedImage = try service.croppedImage(from: image, region: region)

        #expect(croppedImage.width == 50)
        #expect(croppedImage.height == 40)
    }

    private func makeImage(size: CGSize) throws -> CGImage {
        guard let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw ServiceError.processingFailed("Testbild konnte nicht vorbereitet werden.")
        }

        context.setFillColor(CGColor(red: 1, green: 0.5, blue: 0, alpha: 1))
        context.fill(CGRect(origin: .zero, size: size))

        guard let image = context.makeImage() else {
            throw ServiceError.processingFailed("Testbild besitzt keine CGImage-Repräsentation.")
        }

        return image
    }
}
