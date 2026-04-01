import Foundation

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

