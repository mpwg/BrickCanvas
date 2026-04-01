import Foundation

struct MatchableColorSample: Codable, Hashable, Sendable {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
}

struct ColorMatchRequest: Hashable, Sendable {
    let sample: MatchableColorSample
    let palette: PaletteDescriptor
}

struct ColorMatchResult: Hashable, Sendable {
    let matchedColor: BrickColor
}

protocol ColorMatcherService: Sendable {
    func nearestColor(for request: ColorMatchRequest) async throws -> ColorMatchResult
}

