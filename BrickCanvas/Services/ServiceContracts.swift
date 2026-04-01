import Foundation

enum ServiceError: Error, Equatable, LocalizedError, Sendable {
    case invalidInput(String)
    case unavailable(String)
    case processingFailed(String)
    case unsupportedOperation(String)

    var errorDescription: String? {
        switch self {
        case let .invalidInput(message),
             let .unavailable(message),
             let .processingFailed(message),
             let .unsupportedOperation(message):
            message
        }
    }
}

/// Rohes Bildartefakt fuer Service-Grenzen ohne UIKit-Abhaengigkeit.
struct ImageDataAsset: Codable, Hashable, Sendable {
    let data: Data
    let filename: String
    let pixelWidth: Int
    let pixelHeight: Int
    let mimeType: String
}

struct ImportedImage: Codable, Hashable, Sendable {
    let source: ProjectImportSource
    let asset: ImageDataAsset
}

struct ExportArtifact: Codable, Hashable, Sendable {
    let filename: String
    let mimeType: String
    let data: Data
}

