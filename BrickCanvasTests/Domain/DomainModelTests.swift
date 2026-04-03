import Foundation
import Testing
@testable import BrickCanvas

struct DomainModelTests {
    @Test
    func generatedProjectCodableRoundTripPreservesIdentity() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(DomainFixtures.generatedProject)
        let decoded = try decoder.decode(BrickCanvasProject.self, from: data)

        #expect(decoded == DomainFixtures.generatedProject)
        #expect(decoded.isGenerated)
    }

    @Test
    func gridRejectsDuplicateCoordinates() throws {
        let size = try MosaicGridSize(width: 2, height: 2)

        do {
            _ = try MosaicGrid(
                size: size,
                cells: [
                    MosaicCell(coordinate: MosaicCoordinate(x: 0, y: 0), colorID: "red"),
                    MosaicCell(coordinate: MosaicCoordinate(x: 0, y: 0), colorID: "blue"),
                    MosaicCell(coordinate: MosaicCoordinate(x: 0, y: 1), colorID: "yellow"),
                    MosaicCell(coordinate: MosaicCoordinate(x: 1, y: 1), colorID: "white")
                ]
            )
            Issue.record("Expected duplicate coordinate error.")
        } catch let error as DomainModelError {
            #expect(error == .duplicateCoordinate(MosaicCoordinate(x: 0, y: 0)))
        }
    }

    @Test
    func gridRejectsCoordinateOutsideBounds() throws {
        let size = try MosaicGridSize(width: 2, height: 2)

        do {
            _ = try MosaicGrid(
                size: size,
                cells: [
                    MosaicCell(coordinate: MosaicCoordinate(x: 0, y: 0), colorID: "red"),
                    MosaicCell(coordinate: MosaicCoordinate(x: 1, y: 0), colorID: "blue"),
                    MosaicCell(coordinate: MosaicCoordinate(x: 2, y: 1), colorID: "yellow"),
                    MosaicCell(coordinate: MosaicCoordinate(x: 1, y: 1), colorID: "white")
                ]
            )
            Issue.record("Expected out-of-bounds coordinate error.")
        } catch let error as DomainModelError {
            #expect(error == .coordinateOutOfBounds(MosaicCoordinate(x: 2, y: 1), size: size))
        }
    }

    @Test
    func partRequirementIdentityIsStableAcrossFixtures() throws {
        let ids = Set(DomainFixtures.partRequirements.map(\.id))

        #expect(ids.count == DomainFixtures.partRequirements.count)
        #expect(ids.contains("round_plate_1x1::bright-red"))
    }

    @Test
    func mosaicSizePresetsMapToExpectedGridSizes() throws {
        let expectedSizes: [MosaicSizePreset: MosaicGridSize] = [
            .small24x24: try MosaicGridSize(width: 24, height: 24),
            .medium48x48: try MosaicGridSize(width: 48, height: 48),
            .large64x64: try MosaicGridSize(width: 64, height: 64)
        ]

        #expect(MosaicSizePreset.allCases.count == expectedSizes.count)

        for preset in MosaicSizePreset.allCases {
            #expect(preset.gridSize == expectedSizes[preset])
            #expect(preset.subtitle.contains("\(preset.gridSize.studCount)"))
        }
    }

    @Test
    func partSummaryContentAggregatesTotalsAndSortsRows() {
        let content = ProjectPartSummaryContent(project: DomainFixtures.generatedProject)

        #expect(content.projectName == "Familienmosaik")
        #expect(content.partName == "Runde Platte 1×1")
        #expect(content.totalPieces == 16)
        #expect(content.distinctColorCount == 4)
        #expect(content.rows.map(\.colorName) == ["Bright Blue", "Bright Red", "Bright Yellow", "White"])
        #expect(content.rows.map(\.quantity) == [5, 4, 4, 3])
    }

    @Test
    func partSummaryStateUsesEmptyStateForDraftProjects() {
        let state = ProjectPartSummaryScreenState(project: DomainFixtures.draftProject)

        guard case let .empty(configuration) = state else {
            Issue.record("Expected empty part summary state for draft project.")
            return
        }

        #expect(configuration.title == "Noch keine Teileliste")
    }

    @Test
    func partSummaryContentFallsBackWhenPaletteColorIsMissing() throws {
        let incompleteArtifacts = GeneratedProjectArtifacts(
            palette: [],
            grid: DomainFixtures.grid,
            partRequirements: [
                try PartRequirement(part: .roundPlate1x1, colorID: "dark-turquoise", quantity: 2)
            ],
            buildPlan: nil
        )
        let project = BrickCanvasProject(
            name: "Fallback",
            lifecycle: .generated,
            sourceImage: DomainFixtures.sourceImage,
            cropRegion: DomainFixtures.cropRegion,
            configuration: DomainFixtures.configuration,
            generatedArtifacts: incompleteArtifacts,
            createdAt: DomainFixtures.createdAt,
            updatedAt: DomainFixtures.updatedAt
        )

        let content = ProjectPartSummaryContent(project: project)

        #expect(content.rows.count == 1)
        #expect(content.rows[0].colorName == "Dark Turquoise")
        #expect(content.rows[0].colorSubtitle == "DARK-TURQUOISE")
    }
}
