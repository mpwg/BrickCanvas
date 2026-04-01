import Foundation

struct PaletteDescriptor: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let colors: [BrickColor]
}

struct PaletteQuery: Hashable, Sendable {
    let paletteID: String
    let includeInactiveColors: Bool

    init(paletteID: String, includeInactiveColors: Bool = false) {
        self.paletteID = paletteID
        self.includeInactiveColors = includeInactiveColors
    }
}

protocol PaletteService: Sendable {
    func availablePalettes() async throws -> [PaletteDescriptor]
    func palette(for query: PaletteQuery) async throws -> PaletteDescriptor
}

