import Foundation
import Testing
@testable import BrickCanvas

struct GeneratedProjectBuilderTests {
    private let builder = GeneratedProjectBuilder()

    @Test
    func builderCreatesGeneratedProjectWithBuildPlanAndParts() async throws {
        let request = GeneratedProjectBuildRequest(
            name: "Familien Mosaik",
            importedImage: ImportedImage(
                source: .photoLibrary,
                asset: ImageDataAsset(
                    data: Data([0x01, 0x02]),
                    filename: "familie-sommer.jpg",
                    pixelWidth: 1_200,
                    pixelHeight: 1_200,
                    mimeType: "image/jpeg"
                )
            ),
            cropRegion: DomainFixtures.cropRegion,
            configuration: DomainFixtures.configuration,
            palette: DomainFixtures.palette,
            grid: DomainFixtures.grid,
            createdAt: DomainFixtures.createdAt
        )

        let project = try await builder.buildProject(from: request)

        #expect(project.name == "Familien Mosaik")
        #expect(project.lifecycle == .generated)
        #expect(project.sourceImage.filename == "familie-sommer.jpg")
        #expect(project.generatedArtifacts?.grid == DomainFixtures.grid)
        #expect(project.generatedArtifacts?.partRequirements == DomainFixtures.partRequirements)
        #expect(project.generatedArtifacts?.buildPlan == DomainFixtures.buildPlan)
    }

    @Test
    func suggestedProjectNameHumanizesImportedFilename() {
        #expect(GeneratedProjectBuilder.suggestedProjectName(from: "familie-sommer_2026.jpg") == "Familie Sommer 2026")
        #expect(GeneratedProjectBuilder.suggestedProjectName(from: ".jpg") == "Neues Mosaik")
    }
}
