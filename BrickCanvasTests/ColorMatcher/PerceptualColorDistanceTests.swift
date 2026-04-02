import Testing
@testable import BrickCanvas

struct PerceptualColorDistanceTests {
    @Test
    func identicalColorsHaveZeroDistance() {
        let color = RGBColor(red: 201, green: 26, blue: 9)

        #expect(PerceptualColorDistance.distance(between: color, and: color) == 0)
        #expect(PerceptualColorDistance.naiveRGBDistance(between: color, and: color) == 0)
    }

    @Test
    func perceptualDistanceIsSymmetric() {
        let left = RGBColor(red: 80, green: 80, blue: 140)
        let right = RGBColor(red: 0, green: 85, blue: 191)

        let forward = PerceptualColorDistance.distance(between: left, and: right)
        let backward = PerceptualColorDistance.distance(between: right, and: left)

        #expect(forward == backward)
    }

    @Test
    func labConversionMatchesExpectedNeutralAnchors() {
        let white = PerceptualColorDistance.labColor(for: RGBColor(red: 255, green: 255, blue: 255))
        let black = PerceptualColorDistance.labColor(for: RGBColor(red: 0, green: 0, blue: 0))

        #expect(abs(white.lightness - 100.0) < 0.01)
        #expect(abs(white.a) < 0.01)
        #expect(abs(white.b) < 0.01)
        #expect(abs(black.lightness) < 0.01)
        #expect(abs(black.a) < 0.01)
        #expect(abs(black.b) < 0.01)
    }

    @Test
    func perceptualDistancePrefersTanOverGrayForWarmSample() async throws {
        let service = try BundledPaletteService()
        let palette = try await service.palette(for: PaletteQuery(paletteID: "mvp-default"))
        let sample = RGBColor(red: 170, green: 150, blue: 120)

        let tan = try #require(palette.colors.first(where: { $0.id == "tan" }))
        let gray = try #require(palette.colors.first(where: { $0.id == "light-bluish-gray" }))

        let perceptualTan = PerceptualColorDistance.distance(between: sample, and: tan.rgb)
        let perceptualGray = PerceptualColorDistance.distance(between: sample, and: gray.rgb)
        let naiveTan = PerceptualColorDistance.naiveRGBDistance(between: sample, and: tan.rgb)
        let naiveGray = PerceptualColorDistance.naiveRGBDistance(between: sample, and: gray.rgb)

        #expect(perceptualTan < perceptualGray)
        #expect(naiveGray < naiveTan)
    }

    @Test
    func perceptualDistancePrefersBlueOverGrayForMutedBlueSample() async throws {
        let service = try BundledPaletteService()
        let palette = try await service.palette(for: PaletteQuery(paletteID: "mvp-default"))
        let sample = RGBColor(red: 80, green: 80, blue: 140)

        let blue = try #require(palette.colors.first(where: { $0.id == "bright-blue" }))
        let gray = try #require(palette.colors.first(where: { $0.id == "dark-bluish-gray" }))

        let perceptualBlue = PerceptualColorDistance.distance(between: sample, and: blue.rgb)
        let perceptualGray = PerceptualColorDistance.distance(between: sample, and: gray.rgb)
        let naiveBlue = PerceptualColorDistance.naiveRGBDistance(between: sample, and: blue.rgb)
        let naiveGray = PerceptualColorDistance.naiveRGBDistance(between: sample, and: gray.rgb)

        #expect(perceptualBlue < perceptualGray)
        #expect(naiveGray < naiveBlue)
    }
}
