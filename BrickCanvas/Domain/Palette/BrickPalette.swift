import Foundation

struct BrickPalette: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let notes: String?
    let colors: [BrickColor]

    var activeColors: [BrickColor] {
        colors.filter(\.isActive)
    }

    func filtered(includeInactiveColors: Bool) -> BrickPalette {
        guard !includeInactiveColors else {
            return self
        }

        return BrickPalette(
            id: id,
            name: name,
            notes: notes,
            colors: activeColors
        )
    }
}

struct PaletteCatalog: Codable, Hashable, Sendable {
    let version: String
    let palettes: [BrickPalette]
}

enum PaletteValidationError: Error, Equatable, LocalizedError, Sendable {
    case emptyCatalog
    case duplicatePaletteID(String)
    case duplicateColorID(paletteID: String, colorID: String)
    case emptyPaletteName(String)
    case emptyColorName(paletteID: String, colorID: String)
    case paletteWithoutColors(String)

    var errorDescription: String? {
        switch self {
        case .emptyCatalog:
            "Der Palette-Katalog ist leer."
        case let .duplicatePaletteID(id):
            "Doppelte Palette-ID: \(id)."
        case let .duplicateColorID(paletteID, colorID):
            "Doppelte Farb-ID \(colorID) in Palette \(paletteID)."
        case let .emptyPaletteName(id):
            "Palette \(id) hat keinen Anzeigenamen."
        case let .emptyColorName(paletteID, colorID):
            "Farbe \(colorID) in Palette \(paletteID) hat keinen Anzeigenamen."
        case let .paletteWithoutColors(id):
            "Palette \(id) enthält keine Farben."
        }
    }
}

extension PaletteCatalog {
    func validated() throws -> PaletteCatalog {
        guard !palettes.isEmpty else {
            throw PaletteValidationError.emptyCatalog
        }

        var seenPaletteIDs = Set<String>()

        for palette in palettes {
            let trimmedPaletteName = palette.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedPaletteName.isEmpty else {
                throw PaletteValidationError.emptyPaletteName(palette.id)
            }

            guard !palette.colors.isEmpty else {
                throw PaletteValidationError.paletteWithoutColors(palette.id)
            }

            let insertedPalette = seenPaletteIDs.insert(palette.id).inserted
            if !insertedPalette {
                throw PaletteValidationError.duplicatePaletteID(palette.id)
            }

            var seenColorIDs = Set<String>()
            for color in palette.colors {
                let trimmedColorName = color.name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedColorName.isEmpty else {
                    throw PaletteValidationError.emptyColorName(paletteID: palette.id, colorID: color.id)
                }

                let insertedColor = seenColorIDs.insert(color.id).inserted
                if !insertedColor {
                    throw PaletteValidationError.duplicateColorID(paletteID: palette.id, colorID: color.id)
                }
            }
        }

        return self
    }
}

