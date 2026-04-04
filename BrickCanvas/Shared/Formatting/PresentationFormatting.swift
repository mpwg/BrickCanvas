import Foundation

extension BrickPart {
    var displayName: String {
        switch self {
        case .roundPlate1x1:
            "Runde Platte 1×1"
        case .squarePlate1x1:
            "Quadratische Platte 1×1"
        case .tile1x1:
            "Fliese 1×1"
        }
    }
}

extension String {
    var humanizedColorID: String {
        split(separator: "-")
            .map { segment in
                segment.prefix(1).uppercased() + segment.dropFirst()
            }
            .joined(separator: " ")
    }
}
