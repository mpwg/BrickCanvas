import Foundation

enum PaletteListMode: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
    case simple
    case complete
    case custom

    static let storageKey = "paletteListMode"

    var id: Self { self }

    var title: String {
        switch self {
        case .simple:
            "Basis"
        case .complete:
            "Alle"
        case .custom:
            "Individuell"
        }
    }

    var description: String {
        switch self {
        case .simple:
            "Aktiviert nur die standardmäßig vorgesehenen Basisfarben."
        case .complete:
            "Aktiviert die vollständige LEGO-Palette."
        case .custom:
            "Beliebige Einzelwahl pro Farbe. Das Dithering nutzt nur aktivierte Farben."
        }
    }
}
