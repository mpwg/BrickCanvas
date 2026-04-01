import Foundation

enum ExportFormat: String, Codable, Hashable, Sendable {
    case previewImage
    case buildPlanImage
    case partsListText
}

struct ExportRequest: Hashable, Sendable {
    let project: BrickCanvasProject
    let format: ExportFormat
}

protocol ExportEngine: Sendable {
    func export(_ request: ExportRequest) async throws -> ExportArtifact
}

