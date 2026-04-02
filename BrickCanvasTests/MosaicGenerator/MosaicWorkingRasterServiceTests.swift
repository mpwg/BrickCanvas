import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import BrickCanvas

struct MosaicWorkingRasterServiceTests {
    private let service = HighQualityMosaicWorkingRasterService()

    @Test
    func workingRasterMatchesRequestedStudDimensions() async throws {
        let image = try makeSolidImage(size: CGSize(width: 96, height: 96), color: RGBColor(red: 240, green: 120, blue: 30))
        let request = try makeRequest(
            image: image,
            cropRegion: CropRegion(originX: 0, originY: 0, width: 1, height: 1),
            mosaicSize: MosaicGridSize(width: 24, height: 24)
        )

        let raster = try await service.makeWorkingRaster(from: request)

        #expect(raster.size == request.configuration.mosaicSize)
        #expect(raster.pixels.count == 24 * 24)
        assertColor(
            raster.color(at: MosaicCoordinate(x: 12, y: 12)),
            approximatelyEquals: RGBColor(red: 240, green: 120, blue: 30),
            tolerance: 20
        )
    }

    @Test
    func workingRasterUsesRequestedCropRegion() async throws {
        let image = try makeStripedImage()
        let request = try makeRequest(
            image: image,
            cropRegion: CropRegion(originX: 1.0 / 3.0, originY: 0, width: 1.0 / 3.0, height: 1),
            mosaicSize: MosaicGridSize(width: 2, height: 2)
        )

        let raster = try await service.makeWorkingRaster(from: request)

        for y in 0..<2 {
            for x in 0..<2 {
                assertColor(
                    raster.color(at: MosaicCoordinate(x: x, y: y)),
                    approximatelyEquals: RGBColor(red: 0, green: 180, blue: 0),
                    tolerance: 12
                )
            }
        }
    }

    @Test
    func workingRasterAveragesHighFrequencyPatternsInsteadOfAliasing() async throws {
        let image = try makeCheckerboardImage(size: CGSize(width: 40, height: 40))
        let request = try makeRequest(
            image: image,
            cropRegion: CropRegion(originX: 0, originY: 0, width: 1, height: 1),
            mosaicSize: MosaicGridSize(width: 1, height: 1)
        )

        let raster = try await service.makeWorkingRaster(from: request)
        let color = try #require(raster.color(at: MosaicCoordinate(x: 0, y: 0)))

        #expect(abs(Int(color.red) - 128) <= 16)
        #expect(abs(Int(color.green) - 128) <= 16)
        #expect(abs(Int(color.blue) - 128) <= 16)
    }

    private func makeRequest(
        image: ImportedImage,
        cropRegion: CropRegion,
        mosaicSize: MosaicGridSize
    ) throws -> MosaicGenerationRequest {
        MosaicGenerationRequest(
            image: image,
            cropRegion: cropRegion,
            configuration: MosaicConfiguration(
                mosaicSize: mosaicSize,
                paletteID: "mvp-default",
                part: .roundPlate1x1
            ),
            palette: DomainFixtures.paletteDescriptor
        )
    }

    private func makeSolidImage(size: CGSize, color: RGBColor) throws -> ImportedImage {
        let cgImage = try makeImage(size: size) { context in
            context.setFillColor(CGColor(
                red: CGFloat(color.red) / 255,
                green: CGFloat(color.green) / 255,
                blue: CGFloat(color.blue) / 255,
                alpha: 1
            ))
            context.fill(CGRect(origin: .zero, size: size))
        }

        return try makeImportedImage(from: cgImage, filename: "solid.png")
    }

    private func makeStripedImage() throws -> ImportedImage {
        let size = CGSize(width: 12, height: 4)
        let cgImage = try makeImage(size: size) { context in
            context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
            context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))

            context.setFillColor(CGColor(red: 0, green: 180.0 / 255.0, blue: 0, alpha: 1))
            context.fill(CGRect(x: 4, y: 0, width: 4, height: 4))

            context.setFillColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1))
            context.fill(CGRect(x: 8, y: 0, width: 4, height: 4))
        }

        return try makeImportedImage(from: cgImage, filename: "stripes.png")
    }

    private func makeCheckerboardImage(size: CGSize) throws -> ImportedImage {
        let cgImage = try makeImage(size: size) { context in
            let width = Int(size.width)
            let height = Int(size.height)

            for y in 0..<height {
                for x in 0..<width {
                    let isWhite = (x + y).isMultiple(of: 2)
                    let value: CGFloat = isWhite ? 1 : 0
                    context.setFillColor(CGColor(red: value, green: value, blue: value, alpha: 1))
                    context.fill(CGRect(x: x, y: y, width: 1, height: 1))
                }
            }
        }

        return try makeImportedImage(from: cgImage, filename: "checkerboard.png")
    }

    private func makeImage(size: CGSize, drawing: (CGContext) -> Void) throws -> CGImage {
        guard let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw ServiceError.processingFailed("Testbild konnte nicht vorbereitet werden.")
        }

        drawing(context)

        guard let image = context.makeImage() else {
            throw ServiceError.processingFailed("Testbild besitzt keine CGImage-Repräsentation.")
        }

        return image
    }

    private func makeImportedImage(from image: CGImage, filename: String) throws -> ImportedImage {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else {
            throw ServiceError.processingFailed("PNG-Zieldaten konnten nicht vorbereitet werden.")
        }

        CGImageDestinationAddImage(destination, image, nil)

        guard CGImageDestinationFinalize(destination) else {
            throw ServiceError.processingFailed("PNG-Testbild konnte nicht finalisiert werden.")
        }

        return ImportedImage(
            source: .photoLibrary,
            asset: ImageDataAsset(
                data: data as Data,
                filename: filename,
                pixelWidth: image.width,
                pixelHeight: image.height,
                mimeType: UTType.png.preferredMIMEType ?? "image/png"
            )
        )
    }
}

private extension DomainFixtures {
    static var paletteDescriptor: BrickPalette {
        BrickPalette(
            id: "fixture-palette",
            name: "Fixture Palette",
            notes: nil,
            colors: palette
        )
    }
}

private func assertColor(
    _ actual: RGBColor?,
    approximatelyEquals expected: RGBColor,
    tolerance: Int
) {
    #expect(actual != nil)
    let color = actual ?? RGBColor(red: 0, green: 0, blue: 0)

    #expect(abs(Int(color.red) - Int(expected.red)) <= tolerance)
    #expect(abs(Int(color.green) - Int(expected.green)) <= tolerance)
    #expect(abs(Int(color.blue) - Int(expected.blue)) <= tolerance)
}
