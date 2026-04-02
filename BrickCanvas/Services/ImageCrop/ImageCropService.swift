import CoreGraphics
import Foundation

struct CropLayout: Equatable, Sendable {
    let imageDisplaySize: CGSize
    let constrainedOffset: CGSize
    let cropRegion: CropRegion
    let cropFrame: CGRect
}

protocol ImageCropService: Sendable {
    func layout(
        imageSize: CGSize,
        canvasSize: CGSize,
        cropFrame: CGRect,
        zoomScale: CGFloat,
        proposedOffset: CGSize
    ) -> CropLayout

    func offset(
        preservingNormalizedCenter center: CGPoint,
        imageSize: CGSize,
        canvasSize: CGSize,
        cropFrame: CGRect,
        zoomScale: CGFloat
    ) -> CGSize

    func croppedImage(from image: CGImage, region: CropRegion) throws -> CGImage
}

struct DefaultImageCropService: ImageCropService {
    private let minimumZoomScale: CGFloat = 1

    func layout(
        imageSize: CGSize,
        canvasSize: CGSize,
        cropFrame: CGRect,
        zoomScale: CGFloat,
        proposedOffset: CGSize
    ) -> CropLayout {
        let safeImageSize = CGSize(
            width: max(imageSize.width, 1),
            height: max(imageSize.height, 1)
        )
        let safeCanvasSize = CGSize(
            width: max(canvasSize.width, 1),
            height: max(canvasSize.height, 1)
        )
        let safeCropFrame = cropFrame.standardized
        let resolvedZoomScale = max(zoomScale, minimumZoomScale)
        let baseScale = max(
            safeCanvasSize.width / safeImageSize.width,
            safeCanvasSize.height / safeImageSize.height
        )
        let displaySize = CGSize(
            width: safeImageSize.width * baseScale * resolvedZoomScale,
            height: safeImageSize.height * baseScale * resolvedZoomScale
        )
        let maxHorizontalOffset = max((displaySize.width - safeCropFrame.width) / 2, 0)
        let maxVerticalOffset = max((displaySize.height - safeCropFrame.height) / 2, 0)
        let constrainedOffset = CGSize(
            width: proposedOffset.width.clamped(to: -maxHorizontalOffset...maxHorizontalOffset),
            height: proposedOffset.height.clamped(to: -maxVerticalOffset...maxVerticalOffset)
        )

        let originX = ((displaySize.width - safeCropFrame.width) / 2 - constrainedOffset.width) / displaySize.width
        let originY = ((displaySize.height - safeCropFrame.height) / 2 - constrainedOffset.height) / displaySize.height
        let width = safeCropFrame.width / displaySize.width
        let height = safeCropFrame.height / displaySize.height

        return CropLayout(
            imageDisplaySize: displaySize,
            constrainedOffset: constrainedOffset,
            cropRegion: CropRegion(
                originX: originX.clamped(to: 0...1),
                originY: originY.clamped(to: 0...1),
                width: width.clamped(to: 0...1),
                height: height.clamped(to: 0...1)
            ),
            cropFrame: safeCropFrame
        )
    }

    func croppedImage(from image: CGImage, region: CropRegion) throws -> CGImage {
        let imageBounds = CGRect(x: 0, y: 0, width: image.width, height: image.height)
        let cropRect = CGRect(
            x: CGFloat(region.originX) * imageBounds.width,
            y: CGFloat(region.originY) * imageBounds.height,
            width: CGFloat(region.width) * imageBounds.width,
            height: CGFloat(region.height) * imageBounds.height
        )
        .integral
        .intersection(imageBounds)

        guard cropRect.width >= 1, cropRect.height >= 1 else {
            throw ServiceError.invalidInput("Der Zuschnitt liegt außerhalb des Bildbereichs.")
        }

        guard let croppedImage = image.cropping(to: cropRect) else {
            throw ServiceError.processingFailed("Die Live-Vorschau für den Zuschnitt konnte nicht erzeugt werden.")
        }

        return croppedImage
    }

    func offset(
        preservingNormalizedCenter center: CGPoint,
        imageSize: CGSize,
        canvasSize: CGSize,
        cropFrame: CGRect,
        zoomScale: CGFloat
    ) -> CGSize {
        let safeImageSize = CGSize(
            width: max(imageSize.width, 1),
            height: max(imageSize.height, 1)
        )
        let safeCanvasSize = CGSize(
            width: max(canvasSize.width, 1),
            height: max(canvasSize.height, 1)
        )
        let safeCropFrame = cropFrame.standardized
        let resolvedZoomScale = max(zoomScale, minimumZoomScale)
        let baseScale = max(
            safeCanvasSize.width / safeImageSize.width,
            safeCanvasSize.height / safeImageSize.height
        )
        let displaySize = CGSize(
            width: safeImageSize.width * baseScale * resolvedZoomScale,
            height: safeImageSize.height * baseScale * resolvedZoomScale
        )
        let visibleWidth = safeCropFrame.width / displaySize.width
        let visibleHeight = safeCropFrame.height / displaySize.height
        let originX = CGFloat(center.x) - visibleWidth / 2
        let originY = CGFloat(center.y) - visibleHeight / 2

        return CGSize(
            width: (displaySize.width - safeCropFrame.width) / 2 - originX * displaySize.width,
            height: (displaySize.height - safeCropFrame.height) / 2 - originY * displaySize.height
        )
    }
}

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
