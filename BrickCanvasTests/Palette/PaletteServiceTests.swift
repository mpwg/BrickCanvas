import Foundation
import Testing
@testable import BrickCanvas

struct PaletteServiceTests {
    @Test
    func bundledPaletteServiceLoadsDefaultPalette() async throws {
        let service = try BundledPaletteService()

        let palette = try await service.palette(for: PaletteQuery(paletteID: "mvp-default"))

        #expect(palette.id == "mvp-default")
        #expect(palette.colors.count == 12)
        #expect(palette.colors.contains(where: { $0.id == "bright-red" }))
        #expect(palette.colors.contains(where: { $0.id == "medium-blue" }))
        #expect(palette.colors.contains(where: { $0.id == "light-bluish-gray" }))
    }

    @Test
    func bundledPaletteServiceEnumeratesAvailablePalettes() async throws {
        let service = try BundledPaletteService()

        let palettes = try await service.availablePalettes()

        #expect(palettes.count == 1)
        #expect(palettes.first?.name == "LEGO Standardpalette")
    }

    @Test
    func bundledPaletteServiceCanLoadCompletePalette() async throws {
        let service = try BundledPaletteService()

        let palette = try await service.palette(
            for: PaletteQuery(
                paletteID: "mvp-default",
                includeInactiveColors: true
            )
        )

        #expect(palette.colors.count == 232)
        #expect(palette.colors.contains(where: { $0.id == "lego-47-trans-clear" }))
    }

    @Test
    func bundledCompletePaletteDoesNotContainDuplicateRGBValues() async throws {
        let service = try BundledPaletteService()

        let palette = try await service.palette(
            for: PaletteQuery(
                paletteID: "mvp-default",
                includeInactiveColors: true
            )
        )

        let uniqueRGBValues = Set(palette.colors.map(\.rgb))
        #expect(uniqueRGBValues.count == palette.colors.count)
    }

    @Test
    func decoderRejectsDuplicateColorIDs() throws {
        let json = """
        {
          "version": "test",
          "palettes": [
            {
              "id": "test-palette",
              "name": "Test Palette",
              "colors": [
                {
                  "id": "red",
                  "name": "Red",
                  "rgb": { "red": 255, "green": 0, "blue": 0 },
                  "isActive": true,
                  "notes": null
                },
                {
                  "id": "red",
                  "name": "Other Red",
                  "rgb": { "red": 200, "green": 0, "blue": 0 },
                  "isActive": true,
                  "notes": null
                }
              ]
            }
          ]
        }
        """

        do {
            _ = try PaletteCatalogDecoder.decode(data: Data(json.utf8))
            Issue.record("Expected duplicate color ID validation error.")
        } catch let error as PaletteValidationError {
            #expect(error == .duplicateColorID(paletteID: "test-palette", colorID: "red"))
        }
    }

    @Test
    func paletteQueryFiltersInactiveColors() async throws {
        let catalog = try PaletteCatalogDecoder.decode(
            data: Data(
                """
                {
                  "version": "test",
                  "palettes": [
                    {
                      "id": "test-palette",
                      "name": "Test Palette",
                      "notes": null,
                      "colors": [
                        {
                          "id": "active",
                          "name": "Active",
                          "rgb": { "red": 255, "green": 255, "blue": 255 },
                          "isActive": true,
                          "notes": null
                        },
                        {
                          "id": "inactive",
                          "name": "Inactive",
                          "rgb": { "red": 10, "green": 10, "blue": 10 },
                          "isActive": false,
                          "notes": "Nur für Testzwecke."
                        }
                      ]
                    }
                  ]
                }
                """.utf8
            )
        )

        let service = BundledPaletteService(catalog: catalog)

        let filtered = try await service.palette(for: PaletteQuery(paletteID: "test-palette"))
        let full = try await service.palette(for: PaletteQuery(paletteID: "test-palette", includeInactiveColors: true))

        #expect(filtered.colors.count == 1)
        #expect(filtered.colors.first?.id == "active")
        #expect(full.colors.count == 2)
    }

    @Test
    func paletteQueryAppliesCustomActiveColorIDs() async throws {
        let catalog = try PaletteCatalogDecoder.decode(
            data: Data(
                """
                {
                  "version": "test",
                  "palettes": [
                    {
                      "id": "test-palette",
                      "name": "Test Palette",
                      "notes": null,
                      "colors": [
                        {
                          "id": "base",
                          "name": "Base",
                          "rgb": { "red": 255, "green": 255, "blue": 255 },
                          "isActive": true,
                          "notes": null
                        },
                        {
                          "id": "rare",
                          "name": "Rare",
                          "rgb": { "red": 10, "green": 10, "blue": 10 },
                          "isActive": false,
                          "notes": null
                        }
                      ]
                    }
                  ]
                }
                """.utf8
            )
        )

        let service = BundledPaletteService(catalog: catalog)

        let filtered = try await service.palette(
            for: PaletteQuery(
                paletteID: "test-palette",
                activeColorIDs: ["rare"]
            )
        )
        let full = try await service.palette(
            for: PaletteQuery(
                paletteID: "test-palette",
                includeInactiveColors: true,
                activeColorIDs: ["rare"]
            )
        )

        #expect(filtered.colors.count == 1)
        #expect(filtered.colors.first?.id == "rare")
        #expect(full.activeColors.map(\.id) == ["rare"])
        #expect(full.colors.first(where: { $0.id == "base" })?.isActive == false)
    }
}
