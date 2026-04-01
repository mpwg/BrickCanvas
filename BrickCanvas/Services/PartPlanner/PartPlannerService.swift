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

