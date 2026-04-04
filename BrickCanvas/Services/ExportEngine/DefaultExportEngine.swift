import Foundation

struct DefaultExportEngine: ExportEngine {
    func export(_ request: ExportRequest) async throws -> ExportArtifact {
        switch request.format {
        case .buildPlanImage:
            try exportBuildPlanImage(for: request.project)
        case .previewImage:
            throw ServiceError.unsupportedOperation("Der Export der Vorschau ist noch nicht implementiert.")
        case .partsListText:
            throw ServiceError.unsupportedOperation("Der Export der Teileliste ist noch nicht implementiert.")
        }
    }

    func exportBuildPlanImage(for project: BrickCanvasProject) throws -> ExportArtifact {
        guard let document = BuildPlanRenderDocument(project: project) else {
            throw ServiceError.unavailable("Für dieses Projekt liegt noch kein renderbarer Bauplan vor.")
        }

        let data = try BuildPlanRasterizer.makePNGData(
            document: document,
            configuration: .export
        )

        return ExportArtifact(
            filename: "\(project.name.exportFileComponent)-bauplan.png",
            mimeType: "image/png",
            data: data
        )
    }
}

private extension String {
    var exportFileComponent: String {
        let components = lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.isEmpty == false }

        return components.isEmpty ? "brickcanvas-projekt" : components.joined(separator: "-")
    }
}
