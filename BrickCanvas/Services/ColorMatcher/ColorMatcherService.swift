import Foundation

struct MatchableColorSample: Codable, Hashable, Sendable {
    let red: UInt8
    let green: UInt8
    let blue: UInt8

    var rgbColor: RGBColor {
        RGBColor(red: red, green: green, blue: blue)
    }

    init(red: UInt8, green: UInt8, blue: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    init(rgbColor: RGBColor) {
        self.init(red: rgbColor.red, green: rgbColor.green, blue: rgbColor.blue)
    }
}

struct ColorMatchRequest: Hashable, Sendable {
    let sample: MatchableColorSample
    let palette: PaletteDescriptor
    let allowedColorIDs: Set<String>?

    init(sample: MatchableColorSample, palette: PaletteDescriptor, allowedColorIDs: Set<String>? = nil) {
        self.sample = sample
        self.palette = palette
        self.allowedColorIDs = allowedColorIDs
    }
}

struct ColorMatchResult: Hashable, Sendable {
    let matchedColor: BrickColor
}

protocol ColorMatcherService: Sendable {
    func nearestColor(for request: ColorMatchRequest) async throws -> ColorMatchResult
}

struct PerceptualColorMatcherService: ColorMatcherService {
    func nearestColor(for request: ColorMatchRequest) async throws -> ColorMatchResult {
        let candidateColors = availableColors(for: request)

        guard let matchedColor = candidateColors.min(by: { lhs, rhs in
            compare(lhs: lhs, rhs: rhs, sample: request.sample.rgbColor)
        }) else {
            throw ServiceError.invalidInput("Die Farbpalette enthält keine matchbaren Farben.")
        }

        return ColorMatchResult(matchedColor: matchedColor)
    }

    private func availableColors(for request: ColorMatchRequest) -> [BrickColor] {
        guard let allowedColorIDs = request.allowedColorIDs, !allowedColorIDs.isEmpty else {
            return request.palette.colors
        }

        return request.palette.colors.filter { allowedColorIDs.contains($0.id) }
    }

    private func compare(lhs: BrickColor, rhs: BrickColor, sample: RGBColor) -> Bool {
        let lhsDistance = PerceptualColorDistance.distance(between: sample, and: lhs.rgb)
        let rhsDistance = PerceptualColorDistance.distance(between: sample, and: rhs.rgb)

        if lhsDistance != rhsDistance {
            return lhsDistance < rhsDistance
        }

        let lhsNaiveDistance = PerceptualColorDistance.naiveRGBDistance(between: sample, and: lhs.rgb)
        let rhsNaiveDistance = PerceptualColorDistance.naiveRGBDistance(between: sample, and: rhs.rgb)

        if lhsNaiveDistance != rhsNaiveDistance {
            return lhsNaiveDistance < rhsNaiveDistance
        }

        return lhs.id < rhs.id
    }
}
