import Foundation

enum DomainFixtures {
    static let createdAt = Date(timeIntervalSince1970: 1_712_448_000)
    static let updatedAt = Date(timeIntervalSince1970: 1_712_451_600)

    static let palette: [BrickColor] = [
        BrickColor(id: "bright-red", name: "Bright Red", rgb: RGBColor(red: 201, green: 26, blue: 9)),
        BrickColor(id: "bright-blue", name: "Bright Blue", rgb: RGBColor(red: 0, green: 85, blue: 191)),
        BrickColor(id: "bright-yellow", name: "Bright Yellow", rgb: RGBColor(red: 242, green: 205, blue: 55)),
        BrickColor(id: "white", name: "White", rgb: RGBColor(red: 255, green: 255, blue: 255))
    ]

    static let sourceImage = SourceImageReference(
        source: .photoLibrary,
        filename: "family-portrait.jpg",
        pixelWidth: 3024,
        pixelHeight: 4032
    )

    static let cropRegion = CropRegion(
        originX: 0.1,
        originY: 0.08,
        width: 0.8,
        height: 0.8
    )

    static let configuration = MosaicConfiguration(
        mosaicSize: try! MosaicGridSize(width: 4, height: 4),
        paletteID: "mvp-default",
        part: .roundPlate1x1,
        ditheringMethod: .floydSteinberg
    )

    static let grid = try! MosaicGrid(
        size: configuration.mosaicSize,
        cells: [
            MosaicCell(coordinate: MosaicCoordinate(x: 0, y: 0), colorID: "bright-red"),
            MosaicCell(coordinate: MosaicCoordinate(x: 1, y: 0), colorID: "bright-red"),
            MosaicCell(coordinate: MosaicCoordinate(x: 2, y: 0), colorID: "bright-blue"),
            MosaicCell(coordinate: MosaicCoordinate(x: 3, y: 0), colorID: "bright-blue"),
            MosaicCell(coordinate: MosaicCoordinate(x: 0, y: 1), colorID: "bright-red"),
            MosaicCell(coordinate: MosaicCoordinate(x: 1, y: 1), colorID: "bright-yellow"),
            MosaicCell(coordinate: MosaicCoordinate(x: 2, y: 1), colorID: "bright-yellow"),
            MosaicCell(coordinate: MosaicCoordinate(x: 3, y: 1), colorID: "bright-blue"),
            MosaicCell(coordinate: MosaicCoordinate(x: 0, y: 2), colorID: "white"),
            MosaicCell(coordinate: MosaicCoordinate(x: 1, y: 2), colorID: "bright-yellow"),
            MosaicCell(coordinate: MosaicCoordinate(x: 2, y: 2), colorID: "bright-yellow"),
            MosaicCell(coordinate: MosaicCoordinate(x: 3, y: 2), colorID: "white"),
            MosaicCell(coordinate: MosaicCoordinate(x: 0, y: 3), colorID: "white"),
            MosaicCell(coordinate: MosaicCoordinate(x: 1, y: 3), colorID: "white"),
            MosaicCell(coordinate: MosaicCoordinate(x: 2, y: 3), colorID: "bright-blue"),
            MosaicCell(coordinate: MosaicCoordinate(x: 3, y: 3), colorID: "bright-blue")
        ]
    )

    static let partRequirements: [PartRequirement] = [
        try! PartRequirement(part: .roundPlate1x1, colorID: "bright-red", quantity: 4),
        try! PartRequirement(part: .roundPlate1x1, colorID: "bright-blue", quantity: 5),
        try! PartRequirement(part: .roundPlate1x1, colorID: "bright-yellow", quantity: 4),
        try! PartRequirement(part: .roundPlate1x1, colorID: "white", quantity: 3)
    ]

    static let buildPlan = BuildPlan(
        rows: [
            BuildPlanRow(rowIndex: 0, colorIDs: ["bright-red", "bright-red", "bright-blue", "bright-blue"]),
            BuildPlanRow(rowIndex: 1, colorIDs: ["bright-red", "bright-yellow", "bright-yellow", "bright-blue"]),
            BuildPlanRow(rowIndex: 2, colorIDs: ["white", "bright-yellow", "bright-yellow", "white"]),
            BuildPlanRow(rowIndex: 3, colorIDs: ["white", "white", "bright-blue", "bright-blue"])
        ]
    )

    static let generatedArtifacts = GeneratedProjectArtifacts(
        palette: palette,
        grid: grid,
        partRequirements: partRequirements,
        buildPlan: buildPlan
    )

    static let draftProject = BrickCanvasProject(
        id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
        name: "Sommerportraet",
        lifecycle: .draft,
        sourceImage: sourceImage,
        cropRegion: cropRegion,
        configuration: configuration,
        generatedArtifacts: nil,
        createdAt: createdAt,
        updatedAt: createdAt
    )

    static let generatedProject = BrickCanvasProject(
        id: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
        name: "Familienmosaik",
        lifecycle: .generated,
        sourceImage: sourceImage,
        cropRegion: cropRegion,
        configuration: configuration,
        generatedArtifacts: generatedArtifacts,
        createdAt: createdAt,
        updatedAt: updatedAt
    )
}
