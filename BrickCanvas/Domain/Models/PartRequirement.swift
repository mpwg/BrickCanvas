import Foundation

enum BrickPart: String, Codable, CaseIterable, Hashable, Sendable {
    case roundPlate1x1 = "round_plate_1x1"
    case squarePlate1x1 = "square_plate_1x1"
    case tile1x1 = "tile_1x1"
}

struct PartRequirement: Identifiable, Codable, Hashable, Sendable {
    let part: BrickPart
    let colorID: String
    let quantity: Int

    init(part: BrickPart, colorID: String, quantity: Int) throws {
        guard quantity > 0 else {
            throw DomainModelError.invalidPartQuantity(quantity)
        }

        self.part = part
        self.colorID = colorID
        self.quantity = quantity
    }

    var id: String {
        "\(part.rawValue)::\(colorID)"
    }
}

struct BuildPlanLegendEntry: Identifiable, Codable, Hashable, Sendable {
    let number: Int
    let colorID: String

    var id: Int {
        number
    }
}

struct BuildPlanStud: Codable, Hashable, Sendable {
    let columnIndex: Int
    let colorID: String
    let legendNumber: Int
}

struct BuildPlanRow: Codable, Hashable, Sendable {
    let rowIndex: Int
    let studs: [BuildPlanStud]
}

struct BuildPlan: Codable, Hashable, Sendable {
    let size: MosaicGridSize
    let legend: [BuildPlanLegendEntry]
    let rows: [BuildPlanRow]
}
