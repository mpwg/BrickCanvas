import Foundation

struct MosaicGenerationRequest: Hashable, Sendable {
    let image: ImportedImage
    let cropRegion: CropRegion
    let configuration: MosaicConfiguration
    let palette: PaletteDescriptor
}

struct MosaicGenerationResult: Hashable, Sendable {
    let grid: MosaicGrid
}

protocol MosaicGeneratorService: Sendable {
    func generateMosaic(from request: MosaicGenerationRequest) async throws -> MosaicGenerationResult
}

