import Foundation

enum MosaicSizePreset: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case small24x24
    case medium48x48
    case large64x64

    var id: Self { self }

    var gridSize: MosaicGridSize {
        switch self {
        case .small24x24:
            MosaicSizePreset.size24x24
        case .medium48x48:
            MosaicSizePreset.size48x48
        case .large64x64:
            MosaicSizePreset.size64x64
        }
    }

    var title: String {
        "\(gridSize.width) × \(gridSize.height)"
    }

    var subtitle: String {
        "\(gridSize.studCount) Noppen"
    }

    var accessibilityLabel: String {
        "Mosaikgröße \(gridSize.width) mal \(gridSize.height) Noppen"
    }

    private static let size24x24 = try! MosaicGridSize(width: 24, height: 24)
    private static let size48x48 = try! MosaicGridSize(width: 48, height: 48)
    private static let size64x64 = try! MosaicGridSize(width: 64, height: 64)
}
