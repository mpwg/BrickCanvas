import Testing
@testable import BrickCanvas

struct PipelineFixtureCatalogTests {
    @Test
    func catalogLoadsDeterministicReferenceCases() throws {
        let catalog = try PipelineFixtureRepository.loadCatalog()

        #expect(catalog.version == "2026.04-pipeline-fixtures-v1")
        #expect(catalog.fixtures.count == 2)
        #expect(catalog.fixtures.map(\.id) == ["warm-sunrise-4x4", "neutral-spectrum-3x2"])
    }

    @Test
    func fixtureCasesMaterializeExpectedArtifacts() throws {
        let catalog = try PipelineFixtureRepository.loadCatalog()

        for fixture in catalog.fixtures {
            try fixture.validateShape()

            let grid = try fixture.makeExpectedGrid()
            let buildPlan = fixture.makeExpectedBuildPlan()
            let partRequirements = try fixture.makeExpectedPartRequirements()

            #expect(grid.size.width == fixture.mosaicSize.width)
            #expect(grid.size.height == fixture.mosaicSize.height)
            #expect(buildPlan.rows.count == fixture.mosaicSize.height)
            #expect(partRequirements.isEmpty == false)
        }
    }

    @Test
    func warmSunriseFixtureMatchesSharedDomainFixtures() throws {
        let catalog = try PipelineFixtureRepository.loadCatalog()
        let fixture = try #require(catalog.fixtures.first(where: { $0.id == "warm-sunrise-4x4" }))

        let grid = try fixture.makeExpectedGrid()
        let partRequirements = try fixture.makeExpectedPartRequirements()
        let buildPlan = fixture.makeExpectedBuildPlan()

        #expect(grid == DomainFixtures.grid)
        #expect(partRequirements == DomainFixtures.partRequirements.sorted { $0.id < $1.id })
        #expect(buildPlan == DomainFixtures.buildPlan)
        #expect(fixture.cropRegion == CropRegion(originX: 0.0, originY: 0.0, width: 1.0, height: 1.0))
    }
}
