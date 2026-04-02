import Foundation

enum PaletteListMode: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
    case simple
    case complete

    static let storageKey = "paletteListMode"

    var id: Self { self }

    var title: String {
        switch self {
        case .simple:
            "Einfach"
        case .complete:
            "Vollständig"
        }
    }

    var description: String {
        switch self {
        case .simple:
            "Nur die 12 Basisfarben laut Farbreferenz."
        case .complete:
            "Alle Basisfarben plus seltene Erweiterungsfarben."
        }
    }

    var includesRareColors: Bool {
        switch self {
        case .simple:
            false
        case .complete:
            true
        }
    }
}
