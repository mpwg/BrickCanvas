import Foundation

struct GeneratedProjectBuildRequest: Hashable, Sendable {
    let name: String
    let importedImage: ImportedImage
    let cropRegion: CropRegion
    let configuration: MosaicConfiguration
    let palette: [BrickColor]
    let grid: MosaicGrid
    let createdAt: Date
}

struct GeneratedProjectBuilder {
    let partPlannerService: PartPlannerService
    let buildPlanService: BuildPlanService

    init(
        partPlannerService: PartPlannerService = OneByOnePartPlannerService(),
        buildPlanService: BuildPlanService = SimpleGridBuildPlanService()
    ) {
        self.partPlannerService = partPlannerService
        self.buildPlanService = buildPlanService
    }

    func buildProject(from request: GeneratedProjectBuildRequest) async throws -> BrickCanvasProject {
        let partRequirements = try await partPlannerService.planParts(
            for: PartPlanningRequest(
                grid: request.grid,
                part: request.configuration.part
            )
        ).requirements
        let buildPlan = try await buildPlanService.makeBuildPlan(
            from: BuildPlanRequest(
                grid: request.grid,
                palette: request.palette
            )
        ).buildPlan

        return BrickCanvasProject(
            name: request.name,
            lifecycle: .generated,
            sourceImage: SourceImageReference(
                source: request.importedImage.source,
                filename: request.importedImage.asset.filename,
                pixelWidth: request.importedImage.asset.pixelWidth,
                pixelHeight: request.importedImage.asset.pixelHeight
            ),
            cropRegion: request.cropRegion,
            configuration: request.configuration,
            generatedArtifacts: GeneratedProjectArtifacts(
                palette: request.palette,
                grid: request.grid,
                partRequirements: partRequirements,
                buildPlan: buildPlan
            ),
            createdAt: request.createdAt,
            updatedAt: request.createdAt
        )
    }

    static func suggestedProjectName(from filename: String) -> String {
        let stem = URL(fileURLWithPath: filename).deletingPathExtension().lastPathComponent
        let sanitizedStem = stem.trimmingCharacters(in: .whitespacesAndNewlines)

        guard sanitizedStem.isEmpty == false, sanitizedStem.hasPrefix(".") == false else {
            return "Neues Mosaik"
        }

        let normalized = sanitizedStem
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .split(separator: " ")
            .map { segment in
                segment.prefix(1).uppercased() + segment.dropFirst()
            }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return normalized.isEmpty ? "Neues Mosaik" : normalized
    }
}
