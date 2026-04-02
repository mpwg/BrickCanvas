import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct ImageImportRequest: Hashable, Sendable {
    let source: ProjectImportSource
    let payload: ImageDataAsset
}

struct ImageImportResult: Hashable, Sendable {
    let image: ImportedImage
}

protocol ImageImportService: Sendable {
    func importImage(_ request: ImageImportRequest) async throws -> ImageImportResult
}

struct DefaultImageImportService: ImageImportService {
    func importImage(_ request: ImageImportRequest) async throws -> ImageImportResult {
        guard request.payload.data.isEmpty == false else {
            throw ServiceError.invalidInput("Das ausgewählte Bild enthält keine lesbaren Daten.")
        }

        return try await Task.detached(priority: .userInitiated) {
            try Self.normalizeImage(from: request)
        }.value
    }

    private static func normalizeImage(from request: ImageImportRequest) throws -> ImageImportResult {
        guard let imageSource = CGImageSourceCreateWithData(request.payload.data as CFData, nil) else {
            throw ServiceError.processingFailed("Das gewählte Bild konnte nicht gelesen werden.")
        }

        let pathExtension = URL(fileURLWithPath: request.payload.filename).pathExtension
        let sourceType = (CGImageSourceGetType(imageSource) as String?).flatMap { UTType($0) }

        guard let type = sourceType ?? UTType(mimeType: request.payload.mimeType) ?? UTType(filenameExtension: pathExtension),
              type.conforms(to: UTType.image) else {
            throw ServiceError.unsupportedOperation("Das gewählte Bildformat wird nicht unterstützt.")
        }

        guard let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw ServiceError.processingFailed("Das gewählte Bild konnte nicht geladen werden.")
        }

        let orientation = cgImageOrientation(from: imageSource)
        let normalizedImage = try normalize(cgImage: image, orientation: orientation)

        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw ServiceError.processingFailed("Das Bild konnte nach dem Import nicht normalisiert werden.")
        }

        CGImageDestinationAddImage(destination, normalizedImage, nil)

        guard CGImageDestinationFinalize(destination) else {
            throw ServiceError.processingFailed("Das Bild konnte nach dem Import nicht gespeichert werden.")
        }

        let pixelSize = (width: normalizedImage.width, height: normalizedImage.height)
        let filenameBase = URL(fileURLWithPath: request.payload.filename)
            .deletingPathExtension()
            .lastPathComponent
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedFilename = filenameBase.isEmpty ? "imported-image.png" : "\(filenameBase).png"

        return ImageImportResult(
            image: ImportedImage(
                source: request.source,
                asset: ImageDataAsset(
                    data: mutableData as Data,
                    filename: normalizedFilename,
                    pixelWidth: pixelSize.width,
                    pixelHeight: pixelSize.height,
                    mimeType: UTType.png.preferredMIMEType ?? "image/png"
                )
            )
        )
    }
}

private func cgImageOrientation(from imageSource: CGImageSource) -> CGImagePropertyOrientation {
    guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
          let rawValue = properties[kCGImagePropertyOrientation] as? UInt32,
          let orientation = CGImagePropertyOrientation(rawValue: rawValue) else {
        return .up
    }

    return orientation
}

private func normalize(cgImage: CGImage, orientation: CGImagePropertyOrientation) throws -> CGImage {
    let width = cgImage.width
    let height = cgImage.height
    let canvasSize = normalizedCanvasSize(width: width, height: height, orientation: orientation)

    guard let context = CGContext(
        data: nil,
        width: canvasSize.width,
        height: canvasSize.height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw ServiceError.processingFailed("Das Bild konnte nicht in einen Arbeitskontext überführt werden.")
    }

    context.concatenate(normalizationTransform(width: width, height: height, orientation: orientation))

    let drawRect: CGRect
    switch orientation {
    case .left, .leftMirrored, .right, .rightMirrored:
        drawRect = CGRect(x: 0, y: 0, width: height, height: width)
    default:
        drawRect = CGRect(x: 0, y: 0, width: width, height: height)
    }

    context.draw(cgImage, in: drawRect)

    guard let normalizedImage = context.makeImage() else {
        throw ServiceError.processingFailed("Das Bild konnte nicht normalisiert werden.")
    }

    return normalizedImage
}

private func normalizedCanvasSize(width: Int, height: Int, orientation: CGImagePropertyOrientation) -> (width: Int, height: Int) {
    switch orientation {
    case .left, .leftMirrored, .right, .rightMirrored:
        return (width: height, height: width)
    default:
        return (width: width, height: height)
    }
}

private func normalizationTransform(width: Int, height: Int, orientation: CGImagePropertyOrientation) -> CGAffineTransform {
    let width = CGFloat(width)
    let height = CGFloat(height)
    var transform = CGAffineTransform.identity

    switch orientation {
    case .down, .downMirrored:
        transform = transform.translatedBy(x: width, y: height)
        transform = transform.rotated(by: .pi)
    case .left, .leftMirrored:
        transform = transform.translatedBy(x: width, y: 0)
        transform = transform.rotated(by: .pi / 2)
    case .right, .rightMirrored:
        transform = transform.translatedBy(x: 0, y: height)
        transform = transform.rotated(by: -.pi / 2)
    default:
        break
    }

    switch orientation {
    case .upMirrored, .downMirrored:
        transform = transform.translatedBy(x: width, y: 0)
        transform = transform.scaledBy(x: -1, y: 1)
    case .leftMirrored, .rightMirrored:
        transform = transform.translatedBy(x: height, y: 0)
        transform = transform.scaledBy(x: -1, y: 1)
    default:
        break
    }

    return transform
}
