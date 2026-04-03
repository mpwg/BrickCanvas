import Testing
@testable import BrickCanvas

struct PerceptualColorMatcherServiceTests {
    @Test
    func matcherMapsWarmSunriseFixtureToExpectedColorRows() async throws {
        let catalog = try PipelineFixtureRepository.loadCatalog()
        let fixture = try #require(catalog.fixtures.first(where: { $0.id == "warm-sunrise-4x4" }))
        let paletteService = try BundledPaletteService()
        let palette = try await paletteService.palette(for: PaletteQuery(paletteID: fixture.paletteID))
        let matcher = PerceptualColorMatcherService()

        let matchedRows = try await fixture.sourcePixels.asyncMap { row in
            try await row.asyncMap { pixel in
                let result = try await matcher.nearestColor(
                    for: ColorMatchRequest(
                        sample: MatchableColorSample(rgbColor: pixel.rgb),
                        palette: palette
                    )
                )
                return result.matchedColor.id
            }
        }

        #expect(matchedRows == fixture.expectedColorRows)
    }

    @Test
    func matcherMapsNeutralSpectrumFixtureToExpectedColorRows() async throws {
        let catalog = try PipelineFixtureRepository.loadCatalog()
        let fixture = try #require(catalog.fixtures.first(where: { $0.id == "neutral-spectrum-3x2" }))
        let paletteService = try BundledPaletteService()
        let palette = try await paletteService.palette(for: PaletteQuery(paletteID: fixture.paletteID))
        let matcher = PerceptualColorMatcherService()

        let matchedRows = try await fixture.sourcePixels.asyncMap { row in
            try await row.asyncMap { pixel in
                let result = try await matcher.nearestColor(
                    for: ColorMatchRequest(
                        sample: MatchableColorSample(rgbColor: pixel.rgb),
                        palette: palette
                    )
                )
                return result.matchedColor.id
            }
        }

        #expect(matchedRows == fixture.expectedColorRows)
    }

    @Test
    func matcherRespectsAllowedColorRestrictions() async throws {
        let paletteService = try BundledPaletteService()
        let palette = try await paletteService.palette(for: PaletteQuery(paletteID: "mvp-default"))
        let matcher = PerceptualColorMatcherService()

        let result = try await matcher.nearestColor(
            for: ColorMatchRequest(
                sample: MatchableColorSample(red: 254, green: 138, blue: 24),
                palette: palette,
                allowedColorIDs: ["tan", "white", "black"]
            )
        )

        #expect(result.matchedColor.id == "tan")
    }

    @Test
    func matcherBreaksPerfectTiesDeterministicallyByColorID() async throws {
        let palette = BrickPalette(
            id: "test-palette",
            name: "Tie Palette",
            notes: nil,
            colors: [
                BrickColor(id: "beta-red", name: "Beta Red", rgb: RGBColor(red: 200, green: 10, blue: 10)),
                BrickColor(id: "alpha-red", name: "Alpha Red", rgb: RGBColor(red: 200, green: 10, blue: 10))
            ]
        )
        let matcher = PerceptualColorMatcherService()

        let result = try await matcher.nearestColor(
            for: ColorMatchRequest(
                sample: MatchableColorSample(red: 200, green: 10, blue: 10),
                palette: palette
            )
        )

        #expect(result.matchedColor.id == "alpha-red")
    }

    @Test
    func matcherRejectsEmptyCandidateSetAfterRestrictions() async throws {
        let paletteService = try BundledPaletteService()
        let palette = try await paletteService.palette(for: PaletteQuery(paletteID: "mvp-default"))
        let matcher = PerceptualColorMatcherService()

        do {
            _ = try await matcher.nearestColor(
                for: ColorMatchRequest(
                    sample: MatchableColorSample(red: 200, green: 10, blue: 10),
                    palette: palette,
                    allowedColorIDs: ["does-not-exist"]
                )
            )
            Issue.record("Expected invalid input error for empty candidate set.")
        } catch let error as ServiceError {
            #expect(error == .invalidInput("Die Farbpalette enthält keine matchbaren Farben."))
        }
    }

    @Test
    func matcherUsesRareColorsWhenCompletePaletteIsLoaded() async throws {
        let paletteService = try BundledPaletteService()
        let palette = try await paletteService.palette(
            for: PaletteQuery(
                paletteID: "mvp-default",
                includeInactiveColors: true
            )
        )
        let matcher = PerceptualColorMatcherService()

        let result = try await matcher.nearestColor(
            for: ColorMatchRequest(
                sample: MatchableColorSample(red: 252, green: 252, blue: 252),
                palette: palette,
                allowedColorIDs: ["lego-47-trans-clear"]
            )
        )

        #expect(result.matchedColor.id == "lego-47-trans-clear")
    }
}

private extension Array {
    func asyncMap<T>(_ transform: (Element) async throws -> T) async throws -> [T] {
        var results: [T] = []
        results.reserveCapacity(count)

        for element in self {
            try await results.append(transform(element))
        }

        return results
    }
}
