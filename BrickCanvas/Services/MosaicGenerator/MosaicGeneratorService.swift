import Accelerate
import CoreGraphics
import Foundation
import ImageIO

struct MosaicWorkingRaster: Codable, Hashable, Sendable {
    let size: MosaicGridSize
    let pixels: [RGBColor]

    init(size: MosaicGridSize, pixels: [RGBColor]) throws {
        guard pixels.count == size.studCount else {
            throw ServiceError.invalidInput(
                "Das Arbeitsraster enthält \(pixels.count) Pixel, erwartet wurden \(size.studCount)."
            )
        }

        self.size = size
        self.pixels = pixels
    }

    func color(at coordinate: MosaicCoordinate) -> RGBColor? {
        guard (0..<size.width).contains(coordinate.x), (0..<size.height).contains(coordinate.y) else {
            return nil
        }

        return pixels[(coordinate.y * size.width) + coordinate.x]
    }
}

struct MosaicGenerationRequest: Hashable, Sendable {
    let image: ImportedImage
    let cropRegion: CropRegion
    let configuration: MosaicConfiguration
    let palette: PaletteDescriptor
}

struct MosaicGenerationResult: Hashable, Sendable {
    let grid: MosaicGrid
}

protocol MosaicWorkingRasterService: Sendable {
    func makeWorkingRaster(from request: MosaicGenerationRequest) async throws -> MosaicWorkingRaster
}

protocol MosaicGeneratorService: Sendable {
    func generateMosaic(from request: MosaicGenerationRequest) async throws -> MosaicGenerationResult
}

struct HighQualityMosaicWorkingRasterService: MosaicWorkingRasterService {
    private let cropService: ImageCropService

    init(cropService: ImageCropService = DefaultImageCropService()) {
        self.cropService = cropService
    }

    func makeWorkingRaster(from request: MosaicGenerationRequest) async throws -> MosaicWorkingRaster {
        try await Task.detached(priority: .userInitiated) {
            let sourceImage = try decodeImage(from: request.image)
            let croppedImage = try cropService.croppedImage(from: sourceImage, region: request.cropRegion)
            let resizedBuffer = try resize(image: croppedImage, to: request.configuration.mosaicSize)
            defer {
                free(resizedBuffer.data)
            }

            let pixels = makePixels(
                from: resizedBuffer,
                width: request.configuration.mosaicSize.width,
                height: request.configuration.mosaicSize.height
            )

            return try MosaicWorkingRaster(size: request.configuration.mosaicSize, pixels: pixels)
        }.value
    }
}

private func decodeImage(from importedImage: ImportedImage) throws -> CGImage {
    guard importedImage.asset.data.isEmpty == false else {
        throw ServiceError.invalidInput("Das importierte Bild enthält keine lesbaren Daten.")
    }

    guard let imageSource = CGImageSourceCreateWithData(importedImage.asset.data as CFData, nil),
          let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
        throw ServiceError.processingFailed("Das importierte Bild konnte nicht dekodiert werden.")
    }

    return image
}

private func resize(image: CGImage, to targetSize: MosaicGridSize) throws -> vImage_Buffer {
    var sourceFormat = try makeRGBAFormat()
    var sourceBuffer = try makeSourceBuffer(from: image, format: &sourceFormat)
    defer {
        free(sourceBuffer.data)
    }

    var destinationBuffer = try makeDestinationBuffer(size: targetSize)

    let scaleError = vImageScale_ARGB8888(
        &sourceBuffer,
        &destinationBuffer,
        nil,
        vImage_Flags(kvImageHighQualityResampling)
    )

    guard scaleError == kvImageNoError else {
        free(destinationBuffer.data)
        throw ServiceError.processingFailed("Das Bild konnte nicht auf die Zielauflösung heruntergerechnet werden.")
    }

    return destinationBuffer
}

private func makeRGBAFormat() throws -> vImage_CGImageFormat {
    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
        throw ServiceError.processingFailed("Der sRGB-Farbraum konnte nicht vorbereitet werden.")
    }

    let format = vImage_CGImageFormat(
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        colorSpace: Unmanaged.passUnretained(colorSpace),
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue),
        version: 0,
        decode: nil,
        renderingIntent: .defaultIntent
    )

    return format
}

private func makeSourceBuffer(from image: CGImage, format: inout vImage_CGImageFormat) throws -> vImage_Buffer {
    var sourceBuffer = vImage_Buffer()
    let error = vImageBuffer_InitWithCGImage(
        &sourceBuffer,
        &format,
        nil,
        image,
        vImage_Flags(kvImageNoFlags)
    )

    guard error == kvImageNoError else {
        throw ServiceError.processingFailed("Das Quellbild konnte nicht in ein Arbeitsformat überführt werden.")
    }

    return sourceBuffer
}

private func makeDestinationBuffer(size: MosaicGridSize) throws -> vImage_Buffer {
    var destinationBuffer = vImage_Buffer()
    let error = vImageBuffer_Init(
        &destinationBuffer,
        vImagePixelCount(size.height),
        vImagePixelCount(size.width),
        32,
        vImage_Flags(kvImageNoFlags)
    )

    guard error == kvImageNoError else {
        throw ServiceError.processingFailed("Der Zielpuffer für das Arbeitsraster konnte nicht vorbereitet werden.")
    }

    return destinationBuffer
}

private func makePixels(from buffer: vImage_Buffer, width: Int, height: Int) -> [RGBColor] {
    let rowBytes = buffer.rowBytes
    let baseAddress = buffer.data.assumingMemoryBound(to: UInt8.self)
    var pixels: [RGBColor] = []
    pixels.reserveCapacity(width * height)

    for y in 0..<height {
        let rowStart = baseAddress.advanced(by: y * rowBytes)

        for x in 0..<width {
            let pixelStart = rowStart.advanced(by: x * 4)
            pixels.append(
                RGBColor(
                    red: pixelStart[0],
                    green: pixelStart[1],
                    blue: pixelStart[2]
                )
            )
        }
    }

    return pixels
}
