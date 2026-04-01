import Foundation

struct MosaicGridSize: Codable, Hashable, Sendable {
    let width: Int
    let height: Int

    init(width: Int, height: Int) throws {
        guard width > 0, height > 0 else {
            throw DomainModelError.invalidGridSize(width: width, height: height)
        }

        self.width = width
        self.height = height
    }

    var studCount: Int {
        width * height
    }
}

struct MosaicCoordinate: Codable, Hashable, Sendable {
    let x: Int
    let y: Int
}

struct MosaicCell: Codable, Hashable, Sendable {
    let coordinate: MosaicCoordinate
    let colorID: String
}

/// Das Grid ist das zentrale, UI-freie Artefakt fuer Vorschau, Teileplanung und Bauplan.
struct MosaicGrid: Codable, Hashable, Sendable {
    let size: MosaicGridSize
    let cells: [MosaicCell]

    init(size: MosaicGridSize, cells: [MosaicCell]) throws {
        guard cells.count == size.studCount else {
            throw DomainModelError.invalidCellCount(expected: size.studCount, actual: cells.count)
        }

        var seenCoordinates = Set<MosaicCoordinate>()
        for cell in cells {
            guard (0..<size.width).contains(cell.coordinate.x), (0..<size.height).contains(cell.coordinate.y) else {
                throw DomainModelError.coordinateOutOfBounds(cell.coordinate, size: size)
            }

            let inserted = seenCoordinates.insert(cell.coordinate).inserted
            if !inserted {
                throw DomainModelError.duplicateCoordinate(cell.coordinate)
            }
        }

        self.size = size
        self.cells = cells.sorted {
            if $0.coordinate.y == $1.coordinate.y {
                return $0.coordinate.x < $1.coordinate.x
            }

            return $0.coordinate.y < $1.coordinate.y
        }
    }

    func colorID(at coordinate: MosaicCoordinate) -> String? {
        cells.first { $0.coordinate == coordinate }?.colorID
    }
}

