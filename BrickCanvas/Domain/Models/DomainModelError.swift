import Foundation

enum DomainModelError: Error, Equatable, LocalizedError, Sendable {
    case invalidGridSize(width: Int, height: Int)
    case invalidCellCount(expected: Int, actual: Int)
    case duplicateCoordinate(MosaicCoordinate)
    case coordinateOutOfBounds(MosaicCoordinate, size: MosaicGridSize)
    case invalidPartQuantity(Int)

    var errorDescription: String? {
        switch self {
        case let .invalidGridSize(width, height):
            "Ungueltige Grid-Groesse: \(width)x\(height)."
        case let .invalidCellCount(expected, actual):
            "Ungueltige Zellanzahl: erwartet \(expected), erhalten \(actual)."
        case let .duplicateCoordinate(coordinate):
            "Doppelte Koordinate bei (\(coordinate.x), \(coordinate.y))."
        case let .coordinateOutOfBounds(coordinate, size):
            "Koordinate (\(coordinate.x), \(coordinate.y)) liegt ausserhalb von \(size.width)x\(size.height)."
        case let .invalidPartQuantity(quantity):
            "Ungueltige Teilemenge: \(quantity)."
        }
    }
}

