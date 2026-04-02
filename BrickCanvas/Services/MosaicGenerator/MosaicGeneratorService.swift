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

struct ErrorDiffusionMosaicGeneratorService: MosaicGeneratorService {
    private let workingRasterService: MosaicWorkingRasterService
    private let colorMatcher: ColorMatcherService

    init(
        workingRasterService: MosaicWorkingRasterService = HighQualityMosaicWorkingRasterService(),
        colorMatcher: ColorMatcherService = PerceptualColorMatcherService()
    ) {
        self.workingRasterService = workingRasterService
        self.colorMatcher = colorMatcher
    }

    func generateMosaic(from request: MosaicGenerationRequest) async throws -> MosaicGenerationResult {
        let workingRaster = try await workingRasterService.makeWorkingRaster(from: request)
        var diffusionBuffer = workingRaster.pixels.map(DiffusionColor.init)
        var cells: [MosaicCell] = []
        cells.reserveCapacity(workingRaster.size.studCount)
        let strategy = ErrorDiffusionStrategy(method: request.configuration.ditheringMethod)

        for y in 0..<workingRaster.size.height {
            let isLeftToRight = y.isMultiple(of: 2)
            let xRange = isLeftToRight
                ? Array(0..<workingRaster.size.width)
                : Array((0..<workingRaster.size.width).reversed())

            for x in xRange {
                let index = (y * workingRaster.size.width) + x
                let sample = diffusionBuffer[index].clampedRGBColor
                let matched = try await colorMatcher.nearestColor(
                    for: ColorMatchRequest(
                        sample: MatchableColorSample(rgbColor: sample),
                        palette: request.palette
                    )
                ).matchedColor

                cells.append(
                    MosaicCell(
                        coordinate: MosaicCoordinate(x: x, y: y),
                        colorID: matched.id
                    )
                )

                let error = diffusionBuffer[index] - DiffusionColor(rgb: matched.rgb)
                diffuse(
                    error: error,
                    fromX: x,
                    y: y,
                    sample: sample,
                    isLeftToRight: isLeftToRight,
                    strategy: strategy,
                    width: workingRaster.size.width,
                    height: workingRaster.size.height,
                    buffer: &diffusionBuffer
                )
            }
        }

        return MosaicGenerationResult(
            grid: try MosaicGrid(size: workingRaster.size, cells: cells)
        )
    }
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

private struct DiffusionColor {
    var red: Double
    var green: Double
    var blue: Double

    init(rgb: RGBColor) {
        self.red = Double(rgb.red)
        self.green = Double(rgb.green)
        self.blue = Double(rgb.blue)
    }

    var clampedRGBColor: RGBColor {
        RGBColor(
            red: UInt8(red.clamped(to: 0...255).rounded()),
            green: UInt8(green.clamped(to: 0...255).rounded()),
            blue: UInt8(blue.clamped(to: 0...255).rounded())
        )
    }

    static func - (lhs: DiffusionColor, rhs: DiffusionColor) -> DiffusionColor {
        DiffusionColor(
            red: lhs.red - rhs.red,
            green: lhs.green - rhs.green,
            blue: lhs.blue - rhs.blue
        )
    }

    static func + (lhs: DiffusionColor, rhs: DiffusionColor) -> DiffusionColor {
        DiffusionColor(
            red: lhs.red + rhs.red,
            green: lhs.green + rhs.green,
            blue: lhs.blue + rhs.blue
        )
    }

    static func * (lhs: DiffusionColor, rhs: Double) -> DiffusionColor {
        DiffusionColor(
            red: lhs.red * rhs,
            green: lhs.green * rhs,
            blue: lhs.blue * rhs
        )
    }

    private init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}

private struct ErrorDiffusionWeight {
    let dx: Int
    let dy: Int
    let weight: Double
}

private struct ErrorDiffusionStrategy {
    let method: MosaicDitheringMethod

    func weights(for sample: RGBColor, isLeftToRight: Bool) -> [ErrorDiffusionWeight] {
        switch method {
        case .floydSteinberg:
            return isLeftToRight ? Self.floydSteinbergForward : Self.floydSteinbergBackward
        case .ostromoukhov:
            let intensity = DiffusionColor(rgb: sample).normalizedLuminance
            let coefficientSet = OstromoukhovCoefficientSet.forIntensity(intensity)
            return coefficientSet.weights(isLeftToRight: isLeftToRight)
        }
    }

    private static let floydSteinbergForward: [ErrorDiffusionWeight] = [
        ErrorDiffusionWeight(dx: 1, dy: 0, weight: 7.0 / 16.0),
        ErrorDiffusionWeight(dx: -1, dy: 1, weight: 3.0 / 16.0),
        ErrorDiffusionWeight(dx: 0, dy: 1, weight: 5.0 / 16.0),
        ErrorDiffusionWeight(dx: 1, dy: 1, weight: 1.0 / 16.0)
    ]

    private static let floydSteinbergBackward: [ErrorDiffusionWeight] = [
        ErrorDiffusionWeight(dx: -1, dy: 0, weight: 7.0 / 16.0),
        ErrorDiffusionWeight(dx: 1, dy: 1, weight: 3.0 / 16.0),
        ErrorDiffusionWeight(dx: 0, dy: 1, weight: 5.0 / 16.0),
        ErrorDiffusionWeight(dx: -1, dy: 1, weight: 1.0 / 16.0)
    ]
}

private struct OstromoukhovCoefficientSet {
    let right: Double
    let downLeft: Double
    let down: Double

    static func forIntensity(_ intensity: Double) -> Self {
        let index = Int((intensity.clamped(to: 0...1) * 255.0).rounded())
        let divisor = Double(OstromoukhovCoefficients.divisors[index])
        let coefficientIndex = index * 3

        return Self(
            right: Double(OstromoukhovCoefficients.coefficients[coefficientIndex]) / divisor,
            downLeft: Double(OstromoukhovCoefficients.coefficients[coefficientIndex + 1]) / divisor,
            down: Double(OstromoukhovCoefficients.coefficients[coefficientIndex + 2]) / divisor
        )
    }

    func weights(isLeftToRight: Bool) -> [ErrorDiffusionWeight] {
        if isLeftToRight {
            return [
                ErrorDiffusionWeight(dx: 1, dy: 0, weight: right),
                ErrorDiffusionWeight(dx: -1, dy: 1, weight: downLeft),
                ErrorDiffusionWeight(dx: 0, dy: 1, weight: down)
            ]
        }

        return [
            ErrorDiffusionWeight(dx: -1, dy: 0, weight: right),
            ErrorDiffusionWeight(dx: 1, dy: 1, weight: downLeft),
            ErrorDiffusionWeight(dx: 0, dy: 1, weight: down)
        ]
    }
}

private func diffuse(
    error: DiffusionColor,
    fromX x: Int,
    y: Int,
    sample: RGBColor,
    isLeftToRight: Bool,
    strategy: ErrorDiffusionStrategy,
    width: Int,
    height: Int,
    buffer: inout [DiffusionColor]
) {
    let weights = strategy.weights(for: sample, isLeftToRight: isLeftToRight)

    for weight in weights {
        let targetX = x + weight.dx
        let targetY = y + weight.dy

        guard (0..<width).contains(targetX), (0..<height).contains(targetY) else {
            continue
        }

        let index = (targetY * width) + targetX
        buffer[index] = buffer[index] + (error * weight.weight)
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

private extension DiffusionColor {
    var normalizedLuminance: Double {
        let normalizedRed = red.clamped(to: 0...255) / 255.0
        let normalizedGreen = green.clamped(to: 0...255) / 255.0
        let normalizedBlue = blue.clamped(to: 0...255) / 255.0

        return (0.2126 * normalizedRed) + (0.7152 * normalizedGreen) + (0.0722 * normalizedBlue)
    }
}
