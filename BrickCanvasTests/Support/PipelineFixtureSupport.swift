import Foundation
@testable import BrickCanvas

struct PipelineFixtureCatalog: Decodable {
    let version: String
    let fixtures: [PipelineFixture]
}

struct PipelineFixture: Decodable {
    let id: String
    let name: String
    let notes: String?
    let paletteID: String
    let mosaicSize: FixtureGridSize
    let cropRegion: CropRegion
    let sourcePixels: [[FixtureRGBColor]]
    let expectedColorRows: [[String]]
    let expectedPartRequirements: [FixturePartRequirement]
    let expectedBuildPlanRows: [[String]]

    func validateShape() throws {
        guard sourcePixels.count == mosaicSize.height else {
            throw FixtureValidationError.invalidRowCount(
                fixtureID: id,
                section: "sourcePixels",
                expected: mosaicSize.height,
                actual: sourcePixels.count
            )
        }

        guard expectedColorRows.count == mosaicSize.height else {
            throw FixtureValidationError.invalidRowCount(
                fixtureID: id,
                section: "expectedColorRows",
                expected: mosaicSize.height,
                actual: expectedColorRows.count
            )
        }

        guard expectedBuildPlanRows.count == mosaicSize.height else {
            throw FixtureValidationError.invalidRowCount(
                fixtureID: id,
                section: "expectedBuildPlanRows",
                expected: mosaicSize.height,
                actual: expectedBuildPlanRows.count
            )
        }

        for row in sourcePixels {
            guard row.count == mosaicSize.width else {
                throw FixtureValidationError.invalidColumnCount(
                    fixtureID: id,
                    section: "sourcePixels",
                    expected: mosaicSize.width,
                    actual: row.count
                )
            }
        }

        for row in expectedColorRows {
            guard row.count == mosaicSize.width else {
                throw FixtureValidationError.invalidColumnCount(
                    fixtureID: id,
                    section: "expectedColorRows",
                    expected: mosaicSize.width,
                    actual: row.count
                )
            }
        }

        for row in expectedBuildPlanRows {
            guard row.count == mosaicSize.width else {
                throw FixtureValidationError.invalidColumnCount(
                    fixtureID: id,
                    section: "expectedBuildPlanRows",
                    expected: mosaicSize.width,
                    actual: row.count
                )
            }
        }
    }

    func makeExpectedGrid() throws -> MosaicGrid {
        try validateShape()

        let size = try MosaicGridSize(width: mosaicSize.width, height: mosaicSize.height)
        let cells = expectedColorRows.enumerated().flatMap { y, row in
            row.enumerated().map { x, colorID in
                MosaicCell(coordinate: MosaicCoordinate(x: x, y: y), colorID: colorID)
            }
        }

        return try MosaicGrid(size: size, cells: cells)
    }

    func makeExpectedPartRequirements() throws -> [PartRequirement] {
        try expectedPartRequirements
            .map { try PartRequirement(part: $0.part, colorID: $0.colorID, quantity: $0.quantity) }
            .sorted { $0.id < $1.id }
    }

    func makeExpectedBuildPlan() -> BuildPlan {
        BuildPlan(
            rows: expectedBuildPlanRows.enumerated().map { index, colorIDs in
                BuildPlanRow(rowIndex: index, colorIDs: colorIDs)
            }
        )
    }
}

struct FixtureGridSize: Decodable {
    let width: Int
    let height: Int
}

struct FixtureRGBColor: Decodable, Equatable {
    let rgb: RGBColor

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let hexValue = try container.decode(String.self)
        self.rgb = try FixtureRGBColor.decodeHex(hexValue)
    }

    private static func decodeHex(_ hexValue: String) throws -> RGBColor {
        let normalized = hexValue.hasPrefix("#") ? String(hexValue.dropFirst()) : hexValue

        guard normalized.count == 6, let rawValue = UInt32(normalized, radix: 16) else {
            throw FixtureValidationError.invalidHexColor(hexValue)
        }

        return RGBColor(
            red: UInt8((rawValue & 0xFF0000) >> 16),
            green: UInt8((rawValue & 0x00FF00) >> 8),
            blue: UInt8(rawValue & 0x0000FF)
        )
    }
}

struct FixturePartRequirement: Decodable {
    let part: BrickPart
    let colorID: String
    let quantity: Int
}

enum FixtureValidationError: Error, Equatable, CustomStringConvertible {
    case invalidHexColor(String)
    case invalidRowCount(fixtureID: String, section: String, expected: Int, actual: Int)
    case invalidColumnCount(fixtureID: String, section: String, expected: Int, actual: Int)

    var description: String {
        switch self {
        case let .invalidHexColor(value):
            return "Ungueltige Hex-Farbe im Fixture-Katalog: \(value)"
        case let .invalidRowCount(fixtureID, section, expected, actual):
            return "Fixture \(fixtureID) erwartet \(expected) Zeilen in \(section), gefunden: \(actual)."
        case let .invalidColumnCount(fixtureID, section, expected, actual):
            return "Fixture \(fixtureID) erwartet \(expected) Spalten in \(section), gefunden: \(actual)."
        }
    }
}

enum PipelineFixtureRepository {
    static func loadCatalog() throws -> PipelineFixtureCatalog {
        let data = try Data(contentsOf: catalogURL)
        return try JSONDecoder().decode(PipelineFixtureCatalog.self, from: data)
    }

    static var catalogURL: URL {
        let supportFileURL = URL(fileURLWithPath: #filePath)
        let testsDirectoryURL = supportFileURL.deletingLastPathComponent().deletingLastPathComponent()
        let repositoryRootURL = testsDirectoryURL.deletingLastPathComponent()

        return repositoryRootURL
            .appendingPathComponent("BrickCanvas")
            .appendingPathComponent("Resources")
            .appendingPathComponent("Fixtures")
            .appendingPathComponent("pipeline-fixtures-v1.json")
    }
}
