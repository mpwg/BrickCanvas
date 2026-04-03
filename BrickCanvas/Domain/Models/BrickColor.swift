import Foundation

/// Reine Domänenrepräsentation einer LEGO-kompatiblen Farbe.
struct BrickColor: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let rgb: RGBColor
    let isActive: Bool
    let notes: String?

    init(id: String, name: String, rgb: RGBColor, isActive: Bool = true, notes: String? = nil) {
        self.id = id
        self.name = name
        self.rgb = rgb
        self.isActive = isActive
        self.notes = notes
    }

    func with(isActive: Bool) -> BrickColor {
        BrickColor(
            id: id,
            name: name,
            rgb: rgb,
            isActive: isActive,
            notes: notes
        )
    }
}

struct RGBColor: Codable, Hashable, Sendable {
    let red: UInt8
    let green: UInt8
    let blue: UInt8

    init(red: UInt8, green: UInt8, blue: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    var hexString: String {
        String(format: "#%02X%02X%02X", red, green, blue)
    }
}
