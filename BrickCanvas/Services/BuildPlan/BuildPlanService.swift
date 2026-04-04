import Foundation

struct BuildPlanRequest: Hashable, Sendable {
    let grid: MosaicGrid
    let palette: [BrickColor]
}

struct BuildPlanResult: Hashable, Sendable {
    let buildPlan: BuildPlan
}

protocol BuildPlanService: Sendable {
    func makeBuildPlan(from request: BuildPlanRequest) async throws -> BuildPlanResult
}

struct SimpleGridBuildPlanService: BuildPlanService {
    func makeBuildPlan(from request: BuildPlanRequest) async throws -> BuildPlanResult {
        BuildPlanResult(buildPlan: try Self.makeBuildPlanDocument(from: request))
    }

    static func makeBuildPlanDocument(from request: BuildPlanRequest) throws -> BuildPlan {
        var seenColorIDs = Set<String>()
        let usedColorIDsInOrder = request.grid.cells.reduce(into: [String]()) { partialResult, cell in
            guard seenColorIDs.insert(cell.colorID).inserted else {
                return
            }

            partialResult.append(cell.colorID)
        }
        let usedColorIDs = Set(usedColorIDsInOrder)
        let paletteColorIDs = Set(request.palette.map(\.id))
        let paletteOrderedColorIDs = request.palette.compactMap { color in
            usedColorIDs.contains(color.id) ? color.id : nil
        }
        let unknownColorIDs = usedColorIDsInOrder.filter { colorID in
            paletteColorIDs.contains(colorID) == false
        }
        let legendColorIDs = paletteOrderedColorIDs + unknownColorIDs
        let numberByColorID = Dictionary(
            uniqueKeysWithValues: legendColorIDs.enumerated().map { index, colorID in
                (colorID, index + 1)
            }
        )

        let rows = (0..<request.grid.size.height).map { rowIndex in
            let studs = request.grid.cells
                .filter { $0.coordinate.y == rowIndex }
                .map { cell in
                    BuildPlanStud(
                        columnIndex: cell.coordinate.x,
                        colorID: cell.colorID,
                        legendNumber: numberByColorID[cell.colorID] ?? 0
                    )
                }

            return BuildPlanRow(rowIndex: rowIndex, studs: studs)
        }

        return BuildPlan(
            size: request.grid.size,
            legend: legendColorIDs.enumerated().map { index, colorID in
                BuildPlanLegendEntry(number: index + 1, colorID: colorID)
            },
            rows: rows
        )
    }
}
