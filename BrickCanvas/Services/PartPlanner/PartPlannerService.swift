import Foundation

struct PartPlanningRequest: Hashable, Sendable {
    let grid: MosaicGrid
    let part: BrickPart
}

struct PartPlanningResult: Hashable, Sendable {
    let requirements: [PartRequirement]
}

protocol PartPlannerService: Sendable {
    func planParts(for request: PartPlanningRequest) async throws -> PartPlanningResult
}

struct OneByOnePartPlannerService: PartPlannerService {
    func planParts(for request: PartPlanningRequest) async throws -> PartPlanningResult {
        var countsByColorID: [String: Int] = [:]
        var orderedColorIDs: [String] = []

        for cell in request.grid.cells {
            if countsByColorID[cell.colorID] == nil {
                orderedColorIDs.append(cell.colorID)
            }

            countsByColorID[cell.colorID, default: 0] += 1
        }

        let requirements = try orderedColorIDs.map { colorID in
            try PartRequirement(
                part: request.part,
                colorID: colorID,
                quantity: countsByColorID[colorID, default: 0]
            )
        }

        return PartPlanningResult(requirements: requirements)
    }
}
