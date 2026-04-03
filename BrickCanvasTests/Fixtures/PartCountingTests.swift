import Foundation
import Testing
@testable import BrickCanvas

struct PartCountingTests {
    @Test
    func fixturePartRequirementsMatchGridColorCounts() throws {
        let catalog = try PipelineFixtureRepository.loadCatalog()

        for fixture in catalog.fixtures {
            let grid = try fixture.makeExpectedGrid()
            let requirements = try fixture.makeExpectedPartRequirements()
            let quantitiesByColorID = Dictionary(grouping: grid.cells, by: \.colorID)
                .mapValues(\.count)

            #expect(requirements.reduce(into: 0) { $0 += $1.quantity } == grid.size.studCount)
            #expect(Set(requirements.map(\.colorID)) == Set(quantitiesByColorID.keys))

            for requirement in requirements {
                #expect(requirement.quantity == quantitiesByColorID[requirement.colorID])
            }
        }
    }

    @Test
    func sharedDomainFixturePartTotalsMatchStudCount() throws {
        let totalQuantity = DomainFixtures.partRequirements.reduce(into: 0) { $0 += $1.quantity }

        #expect(totalQuantity == DomainFixtures.grid.size.studCount)
    }
}
