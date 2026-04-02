import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import BrickCanvas

struct ImageImportServiceTests {
    @Test
    func importServiceNormalizesRotatedPhotos() async throws {
        let service = DefaultImageImportService()
        let jpegData = try makeJPEGDataWithOrientation(
            size: CGSize(width: 12, height: 20),
            orientation: .right
        )

        let result = try await service.importImage(
            ImageImportRequest(
                source: .photoLibrary,
                payload: ImageDataAsset(
                    data: jpegData,
                    filename: "rotation-test.jpg",
                    pixelWidth: 12,
                    pixelHeight: 20,
                    mimeType: UTType.jpeg.preferredMIMEType ?? "image/jpeg"
                )
            )
        )

        #expect(result.image.asset.mimeType == (UTType.png.preferredMIMEType ?? "image/png"))
        #expect(result.image.asset.filename == "rotation-test.png")
        #expect(result.image.asset.pixelWidth == 20)
        #expect(result.image.asset.pixelHeight == 12)

        let imageSource = try #require(CGImageSourceCreateWithData(result.image.asset.data as CFData, nil))
        let image = try #require(CGImageSourceCreateImageAtIndex(imageSource, 0, nil))

        #expect(image.width == 20)
        #expect(image.height == 12)
    }

    @Test
    func importServiceRejectsInvalidImageData() async throws {
        let service = DefaultImageImportService()

        do {
            _ = try await service.importImage(
                ImageImportRequest(
                    source: .photoLibrary,
                    payload: ImageDataAsset(
                        data: Data("not-an-image".utf8),
                        filename: "broken.bin",
                        pixelWidth: 0,
                        pixelHeight: 0,
                        mimeType: "application/octet-stream"
                    )
                )
            )
            Issue.record("Expected unsupported format error.")
        } catch let error as ServiceError {
            #expect(error == .unsupportedOperation("Das gewählte Bildformat wird nicht unterstützt."))
        }
    }

    private func makeJPEGDataWithOrientation(size: CGSize, orientation: CGImagePropertyOrientation) throws -> Data {
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

        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(origin: .zero, size: size))

        context.setFillColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: size.width / 2, height: size.height / 2))

        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(mutableData, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw ServiceError.processingFailed("Testbild konnte nicht vorbereitet werden.")
        }

        guard let cgImage = context.makeImage() else {
            throw ServiceError.processingFailed("Testbild besitzt keine CGImage-Repräsentation.")
        }

        CGImageDestinationAddImage(
            destination,
            cgImage,
            [kCGImagePropertyOrientation: orientation.rawValue] as CFDictionary
        )

        guard CGImageDestinationFinalize(destination) else {
            throw ServiceError.processingFailed("JPEG-Testbild konnte nicht finalisiert werden.")
        }

        return mutableData as Data
    }
}
