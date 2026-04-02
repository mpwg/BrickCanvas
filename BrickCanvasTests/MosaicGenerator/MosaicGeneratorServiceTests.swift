import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import BrickCanvas

struct MosaicGeneratorServiceTests {
    private let service = ErrorDiffusionMosaicGeneratorService()

    @Test
    func generatorMatchesWarmSunriseFixtureGrid() async throws {
        let catalog = try PipelineFixtureRepository.loadCatalog()
        let fixture = try #require(catalog.fixtures.first(where: { $0.id == "warm-sunrise-4x4" }))
        let expectedGrid = try fixture.makeExpectedGrid()

        let result = try await service.generateMosaic(from: makeRequest(for: fixture))

        #expect(result.grid == expectedGrid)
    }

    @Test
    func generatorMatchesNeutralSpectrumFixtureGrid() async throws {
        let catalog = try PipelineFixtureRepository.loadCatalog()
        let fixture = try #require(catalog.fixtures.first(where: { $0.id == "neutral-spectrum-3x2" }))
        let expectedGrid = try fixture.makeExpectedGrid()

        let result = try await service.generateMosaic(from: makeRequest(for: fixture))

        #expect(result.grid == expectedGrid)
    }

    @Test
    func generatorUsesErrorDiffusionForLimitedPalettes() async throws {
        let size = try MosaicGridSize(width: 4, height: 1)
        let request = try MosaicGenerationRequest(
            image: makeUniformImportedImage(
                width: 4,
                height: 1,
                color: RGBColor(red: 96, green: 96, blue: 96)
            ),
            cropRegion: CropRegion(originX: 0, originY: 0, width: 1, height: 1),
            configuration: MosaicConfiguration(
                mosaicSize: size,
                paletteID: "black-white",
                part: .roundPlate1x1,
                ditheringMethod: .floydSteinberg
            ),
            palette: BrickPalette(
                id: "black-white",
                name: "Black White",
                notes: nil,
                colors: [
                    BrickColor(id: "black", name: "Black", rgb: RGBColor(red: 0, green: 0, blue: 0)),
                    BrickColor(id: "white", name: "White", rgb: RGBColor(red: 255, green: 255, blue: 255))
                ]
            )
        )

        let result = try await service.generateMosaic(from: request)
        let colorIDs = result.grid.cells.map(\.colorID)

        #expect(colorIDs == ["black", "white", "black", "white"])
    }

    @Test
    func generatorSupportsOstromoukhovDithering() async throws {
        let size = try MosaicGridSize(width: 6, height: 1)
        let request = try MosaicGenerationRequest(
            image: makeHorizontalGradientImportedImage(
                width: 6,
                height: 1,
                values: [20, 70, 110, 145, 185, 230]
            ),
            cropRegion: CropRegion(originX: 0, originY: 0, width: 1, height: 1),
            configuration: MosaicConfiguration(
                mosaicSize: size,
                paletteID: "black-white",
                part: .roundPlate1x1,
                ditheringMethod: .ostromoukhov
            ),
            palette: BrickPalette(
                id: "black-white",
                name: "Black White",
                notes: nil,
                colors: [
                    BrickColor(id: "black", name: "Black", rgb: RGBColor(red: 0, green: 0, blue: 0)),
                    BrickColor(id: "white", name: "White", rgb: RGBColor(red: 255, green: 255, blue: 255))
                ]
            )
        )

        let result = try await service.generateMosaic(from: request)
        let colorIDs = result.grid.cells.map(\.colorID)

        #expect(colorIDs.count == 6)
        #expect(Set(colorIDs).isSubset(of: ["black", "white"]))
    }

    private func makeRequest(for fixture: PipelineFixture) throws -> MosaicGenerationRequest {
        MosaicGenerationRequest(
            image: try makeImportedImage(from: fixture.sourcePixels),
            cropRegion: fixture.cropRegion,
            configuration: MosaicConfiguration(
                mosaicSize: try MosaicGridSize(width: fixture.mosaicSize.width, height: fixture.mosaicSize.height),
                paletteID: fixture.paletteID,
                part: .roundPlate1x1,
                ditheringMethod: .floydSteinberg
            ),
            palette: try palette(for: fixture)
        )
    }

    private func palette(for fixture: PipelineFixture) throws -> BrickPalette {
        if fixture.id == "warm-sunrise-4x4" {
            return DomainFixtures.paletteDescriptor
        }

        let colorIDs = Array(Set(fixture.expectedColorRows.flatMap { $0 })).sorted()
        let colors = try colorIDs.map { colorID in
            try #require(DomainFixtures.mvpPalette.colors.first(where: { $0.id == colorID }))
        }

        return BrickPalette(
            id: fixture.paletteID,
            name: "Fixture Palette \(fixture.id)",
            notes: nil,
            colors: colors
        )
    }

    private func makeImportedImage(from rows: [[FixtureRGBColor]]) throws -> ImportedImage {
        let height = rows.count
        let width = try #require(rows.first?.count)

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw ServiceError.processingFailed("Fixture-Bild konnte nicht vorbereitet werden.")
        }

        for (y, row) in rows.enumerated() {
            for (x, pixel) in row.enumerated() {
                let rgb = pixel.rgb
                context.setFillColor(
                    CGColor(
                        red: CGFloat(rgb.red) / 255.0,
                        green: CGFloat(rgb.green) / 255.0,
                        blue: CGFloat(rgb.blue) / 255.0,
                        alpha: 1
                    )
                )
                context.fill(CGRect(x: x, y: height - 1 - y, width: 1, height: 1))
            }
        }

        guard let image = context.makeImage() else {
            throw ServiceError.processingFailed("Fixture-Bild besitzt keine CGImage-Repräsentation.")
        }

        return try makeImportedImage(from: image, filename: "\(width)x\(height)-fixture.png")
    }

    private func makeUniformImportedImage(width: Int, height: Int, color: RGBColor) throws -> ImportedImage {
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw ServiceError.processingFailed("Testbild konnte nicht vorbereitet werden.")
        }

        context.setFillColor(
            CGColor(
                red: CGFloat(color.red) / 255.0,
                green: CGFloat(color.green) / 255.0,
                blue: CGFloat(color.blue) / 255.0,
                alpha: 1
            )
        )
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        guard let image = context.makeImage() else {
            throw ServiceError.processingFailed("Testbild besitzt keine CGImage-Repräsentation.")
        }

        return try makeImportedImage(from: image, filename: "\(width)x\(height)-uniform.png")
    }

    private func makeHorizontalGradientImportedImage(width: Int, height: Int, values: [UInt8]) throws -> ImportedImage {
        guard values.count == width else {
            throw ServiceError.invalidInput("Der Gradienten-Test erwartet genau einen Wert pro Pixelspalte.")
        }

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw ServiceError.processingFailed("Gradienten-Testbild konnte nicht vorbereitet werden.")
        }

        for x in 0..<width {
            let value = CGFloat(values[x]) / 255.0
            context.setFillColor(CGColor(red: value, green: value, blue: value, alpha: 1))
            context.fill(CGRect(x: x, y: 0, width: 1, height: height))
        }

        guard let image = context.makeImage() else {
            throw ServiceError.processingFailed("Gradienten-Testbild besitzt keine CGImage-Repräsentation.")
        }

        return try makeImportedImage(from: image, filename: "\(width)x\(height)-gradient.png")
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
    static let mvpPalette = BrickPalette(
        id: "mvp-default",
        name: "MVP Palette",
        notes: nil,
        colors: [
            BrickColor(id: "bright-red", name: "Bright Red", rgb: RGBColor(red: 201, green: 26, blue: 9)),
            BrickColor(id: "bright-blue", name: "Bright Blue", rgb: RGBColor(red: 0, green: 85, blue: 191)),
            BrickColor(id: "bright-yellow", name: "Bright Yellow", rgb: RGBColor(red: 242, green: 205, blue: 55)),
            BrickColor(id: "white", name: "White", rgb: RGBColor(red: 255, green: 255, blue: 255)),
            BrickColor(id: "black", name: "Black", rgb: RGBColor(red: 27, green: 42, blue: 52)),
            BrickColor(id: "dark-bluish-gray", name: "Dark Bluish Gray", rgb: RGBColor(red: 99, green: 95, blue: 98)),
            BrickColor(id: "light-bluish-gray", name: "Light Bluish Gray", rgb: RGBColor(red: 160, green: 165, blue: 169)),
            BrickColor(id: "tan", name: "Tan", rgb: RGBColor(red: 228, green: 205, blue: 158)),
            BrickColor(id: "bright-orange", name: "Bright Orange", rgb: RGBColor(red: 254, green: 138, blue: 24))
        ]
    )

    static var paletteDescriptor: BrickPalette {
        mvpPalette
    }
}
