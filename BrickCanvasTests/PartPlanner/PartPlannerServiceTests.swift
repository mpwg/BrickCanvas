import Foundation
import Testing
@testable import BrickCanvas

struct PartPlannerServiceTests {
    private let service = OneByOnePartPlannerService()

    @Test
    func plannerAggregatesFixtureGridIntoDeterministicRequirements() async throws {
        let request = PartPlanningRequest(
            grid: DomainFixtures.grid,
            part: .roundPlate1x1
        )

        let result = try await service.planParts(for: request)

        #expect(result.requirements == DomainFixtures.partRequirements)
        #expect(result.requirements.reduce(into: 0) { $0 += $1.quantity } == DomainFixtures.grid.size.studCount)
    }

    @Test
    func plannerKeepsFirstAppearanceOrderForGroupedColors() async throws {
        let grid = try MosaicGrid(
            size: MosaicGridSize(width: 3, height: 2),
            cells: [
                MosaicCell(coordinate: MosaicCoordinate(x: 0, y: 0), colorID: "yellow"),
                MosaicCell(coordinate: MosaicCoordinate(x: 1, y: 0), colorID: "blue"),
                MosaicCell(coordinate: MosaicCoordinate(x: 2, y: 0), colorID: "yellow"),
                MosaicCell(coordinate: MosaicCoordinate(x: 0, y: 1), colorID: "red"),
                MosaicCell(coordinate: MosaicCoordinate(x: 1, y: 1), colorID: "blue"),
                MosaicCell(coordinate: MosaicCoordinate(x: 2, y: 1), colorID: "red")
            ]
        )

        let result = try await service.planParts(
            for: PartPlanningRequest(
                grid: grid,
                part: .tile1x1
            )
        )

        #expect(result.requirements.map(\.colorID) == ["yellow", "blue", "red"])
        #expect(result.requirements.map(\.quantity) == [2, 2, 2])
        #expect(result.requirements.allSatisfy { $0.part == .tile1x1 })
    }

    @Test
    func plannerReturnsOneRequirementPerColorForUniformCounts() async throws {
        let grid = try MosaicGrid(
            size: MosaicGridSize(width: 3, height: 2),
            cells: [
                MosaicCell(coordinate: MosaicCoordinate(x: 0, y: 0), colorID: "black"),
                MosaicCell(coordinate: MosaicCoordinate(x: 1, y: 0), colorID: "dark-bluish-gray"),
                MosaicCell(coordinate: MosaicCoordinate(x: 2, y: 0), colorID: "light-bluish-gray"),
                MosaicCell(coordinate: MosaicCoordinate(x: 0, y: 1), colorID: "tan"),
                MosaicCell(coordinate: MosaicCoordinate(x: 1, y: 1), colorID: "bright-orange"),
                MosaicCell(coordinate: MosaicCoordinate(x: 2, y: 1), colorID: "white")
            ]
        )

        let result = try await service.planParts(
            for: PartPlanningRequest(
                grid: grid,
                part: .squarePlate1x1
            )
        )

        #expect(result.requirements.count == 6)
        #expect(result.requirements.map(\.quantity) == [1, 1, 1, 1, 1, 1])
        #expect(result.requirements.reduce(into: 0) { $0 += $1.quantity } == grid.size.studCount)
    }
}
