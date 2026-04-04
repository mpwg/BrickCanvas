import ImageIO
import Testing
@testable import BrickCanvas

struct ExportEngineTests {
    private let service = DefaultExportEngine()

    @Test
    func buildPlanImageExportProducesPNGArtifact() async throws {
        let artifact = try await service.export(
            ExportRequest(
                project: DomainFixtures.generatedProject,
                format: .buildPlanImage
            )
        )

        #expect(artifact.mimeType == "image/png")
        #expect(artifact.filename.hasSuffix("-bauplan.png"))
        #expect(artifact.data.isEmpty == false)

        let document = try #require(BuildPlanRenderDocument(project: DomainFixtures.generatedProject))
        let canvasSize = BuildPlanRasterizer.canvasSize(
            for: document,
            configuration: .export
        )
        let image = try #require(makeImage(from: artifact.data))

        #expect(image.width == Int(canvasSize.width.rounded(.up)))
        #expect(image.height == Int(canvasSize.height.rounded(.up)))
    }

    @Test
    func buildPlanImageExportFailsWithoutBuildPlan() {
        let project = BrickCanvasProject(
            name: "Ohne Bauplan",
            lifecycle: .generated,
            sourceImage: DomainFixtures.sourceImage,
            cropRegion: DomainFixtures.cropRegion,
            configuration: DomainFixtures.configuration,
            generatedArtifacts: GeneratedProjectArtifacts(
                palette: DomainFixtures.palette,
                grid: DomainFixtures.grid,
                partRequirements: DomainFixtures.partRequirements,
                buildPlan: nil
            ),
            createdAt: DomainFixtures.createdAt,
            updatedAt: DomainFixtures.updatedAt
        )

        #expect(throws: ServiceError.unavailable("Für dieses Projekt liegt noch kein renderbarer Bauplan vor.")) {
            try service.exportBuildPlanImage(for: project)
        }
    }

    private func makeImage(from data: Data) throws -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            Issue.record("PNG data could not be loaded into an image source.")
            return nil
        }

        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}
