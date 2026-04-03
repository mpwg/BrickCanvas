import Foundation

enum PaletteActivationStore {
    static let storageKey = "paletteActivationState"

    static func activeColorIDs(from rawValue: String, for palette: BrickPalette) -> Set<String> {
        let storedIDs = decode(rawValue)[palette.id] ?? []
        let validStoredIDs = storedIDs.intersection(palette.allColorIDs)

        if validStoredIDs.isEmpty {
            return palette.activeColorIDs
        }

        return validStoredIDs
    }

    static func save(activeColorIDs: Set<String>, for paletteID: String, in rawValue: String) -> String {
        var storage = decode(rawValue)
        storage[paletteID] = activeColorIDs
        return encode(storage)
    }

    private static func decode(_ rawValue: String) -> [String: Set<String>] {
        guard let data = rawValue.data(using: .utf8), data.isEmpty == false else {
            return [:]
        }

        let decoder = JSONDecoder()
        guard let storage = try? decoder.decode([String: [String]].self, from: data) else {
            return [:]
        }

        return storage.mapValues(Set.init)
    }

    private static func encode(_ storage: [String: Set<String>]) -> String {
        let encodedStorage = storage
            .mapValues { Array($0).sorted() }
            .filter { $0.value.isEmpty == false }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        guard let data = try? encoder.encode(encodedStorage),
              let string = String(data: data, encoding: .utf8) else {
            return ""
        }

        return string
    }
}
