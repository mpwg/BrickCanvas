import Foundation
import Testing
@testable import BrickCanvas

struct PartCountingTests {
    @Test
    func fixturePartRequirementsMatchStudCounts() throws {
        let catalog = try PipelineFixtureRepository.loadCatalog()

        for fixture in catalog.fixtures {
            let grid = try fixture.makeExpectedGrid()
            let requirements = try fixture.makeExpectedPartRequirements()

            #expect(requirements.reduce(into: 0) { $0 += $1.quantity } == grid.size.studCount)
            #expect(requirements.isEmpty == false)
        }
    }

    @Test
    func sharedDomainFixturePartTotalsMatchStudCount() throws {
        let totalQuantity = DomainFixtures.partRequirements.reduce(into: 0) { $0 += $1.quantity }

        #expect(totalQuantity == DomainFixtures.grid.size.studCount)
    }
}
