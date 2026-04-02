import Foundation

typealias PaletteDescriptor = BrickPalette

struct PaletteQuery: Hashable, Sendable {
    let paletteID: String
    let includeInactiveColors: Bool

    init(paletteID: String, includeInactiveColors: Bool = false) {
        self.paletteID = paletteID
        self.includeInactiveColors = includeInactiveColors
    }

    init(paletteID: String, listMode: PaletteListMode) {
        self.init(
            paletteID: paletteID,
            includeInactiveColors: listMode.includesRareColors
        )
    }
}

protocol PaletteService: Sendable {
    func availablePalettes() async throws -> [PaletteDescriptor]
    func palette(for query: PaletteQuery) async throws -> PaletteDescriptor
}

enum PaletteCatalogDecoder {
    static func decode(data: Data) throws -> PaletteCatalog {
        let decoder = JSONDecoder()
        return try decoder.decode(PaletteCatalog.self, from: data).validated()
    }
}

struct BundledPaletteService: PaletteService {
    private let catalog: PaletteCatalog

    init(bundle: Bundle = .main, resourceName: String = "mvp-palettes-v1") throws {
        let url = bundle.url(forResource: resourceName, withExtension: "json", subdirectory: "Palette")
            ?? bundle.url(forResource: resourceName, withExtension: "json")

        guard let url else {
            throw ServiceError.unavailable("Palette-Ressource \(resourceName).json wurde nicht gefunden.")
        }

        let data = try Data(contentsOf: url)
        self.catalog = try PaletteCatalogDecoder.decode(data: data)
    }

    init(catalog: PaletteCatalog) {
        self.catalog = catalog
    }

    func availablePalettes() async throws -> [PaletteDescriptor] {
        catalog.palettes
    }

    func palette(for query: PaletteQuery) async throws -> PaletteDescriptor {
        guard let palette = catalog.palettes.first(where: { $0.id == query.paletteID }) else {
            throw ServiceError.unavailable("Palette \(query.paletteID) ist nicht verfügbar.")
        }

        return palette.filtered(includeInactiveColors: query.includeInactiveColors)
    }
}
