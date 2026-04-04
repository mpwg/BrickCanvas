import Testing
@testable import BrickCanvas

struct BuildPlanServiceTests {
    private let service = SimpleGridBuildPlanService()

    @Test
    func serviceBuildsDeterministicLegendInPaletteOrder() async throws {
        let buildPlan = try await service.makeBuildPlan(
            from: BuildPlanRequest(
                grid: DomainFixtures.grid,
                palette: DomainFixtures.palette
            )
        ).buildPlan

        #expect(buildPlan.size == DomainFixtures.grid.size)
        #expect(buildPlan.legend.map(\.number) == [1, 2, 3, 4])
        #expect(buildPlan.legend.map(\.colorID) == ["bright-red", "bright-blue", "bright-yellow", "white"])
        #expect(buildPlan.rows.map(\.rowIndex) == [0, 1, 2, 3])
        #expect(buildPlan.rows[0].studs.map(\.legendNumber) == [1, 1, 2, 2])
        #expect(buildPlan.rows[1].studs.map(\.legendNumber) == [1, 3, 3, 2])
        #expect(buildPlan.rows[2].studs.map(\.legendNumber) == [4, 3, 3, 4])
        #expect(buildPlan.rows[3].studs.map(\.legendNumber) == [4, 4, 2, 2])
    }

    @Test
    func serviceAppendsUnknownColorsAfterPaletteColors() async throws {
        let grid = try MosaicGrid(
            size: MosaicGridSize(width: 3, height: 1),
            cells: [
                MosaicCell(coordinate: MosaicCoordinate(x: 0, y: 0), colorID: "unknown-c"),
                MosaicCell(coordinate: MosaicCoordinate(x: 1, y: 0), colorID: "known-b"),
                MosaicCell(coordinate: MosaicCoordinate(x: 2, y: 0), colorID: "unknown-a")
            ]
        )
        let palette = [
            BrickColor(id: "known-a", name: "Known A", rgb: RGBColor(red: 0, green: 0, blue: 0)),
            BrickColor(id: "known-b", name: "Known B", rgb: RGBColor(red: 255, green: 255, blue: 255))
        ]

        let buildPlan = try await service.makeBuildPlan(
            from: BuildPlanRequest(
                grid: grid,
                palette: palette
            )
        ).buildPlan

        #expect(buildPlan.legend.map(\.colorID) == ["known-b", "unknown-c", "unknown-a"])
        #expect(buildPlan.rows[0].studs.map(\.legendNumber) == [2, 1, 3])
    }

    @Test
    func serviceKeepsColumnIndicesAlignedWithGridCoordinates() async throws {
        let buildPlan = try await service.makeBuildPlan(
            from: BuildPlanRequest(
                grid: DomainFixtures.grid,
                palette: DomainFixtures.palette
            )
        ).buildPlan

        #expect(buildPlan.rows.count == DomainFixtures.grid.size.height)

        for row in buildPlan.rows {
            #expect(row.studs.map(\.columnIndex) == Array(0..<DomainFixtures.grid.size.width))
            #expect(row.studs.map(\.colorID) == DomainFixtures.grid.cells.filter { $0.coordinate.y == row.rowIndex }.map(\.colorID))
        }
    }
}
