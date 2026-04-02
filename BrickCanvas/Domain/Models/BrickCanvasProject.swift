import Foundation

enum ProjectImportSource: String, Codable, Hashable, Sendable {
    case photoLibrary
    case camera
    case fileImport
}

enum ProjectLifecycle: String, Codable, Hashable, Sendable {
    case draft
    case generated
    case saved
}

struct SourceImageReference: Codable, Hashable, Sendable {
    let source: ProjectImportSource
    let filename: String
    let pixelWidth: Int
    let pixelHeight: Int
}

struct CropRegion: Codable, Hashable, Sendable {
    let originX: Double
    let originY: Double
    let width: Double
    let height: Double
}

struct MosaicConfiguration: Codable, Hashable, Sendable {
    let mosaicSize: MosaicGridSize
    let paletteID: String
    let part: BrickPart
    let ditheringMethod: MosaicDitheringMethod

    init(
        mosaicSize: MosaicGridSize,
        paletteID: String,
        part: BrickPart,
        ditheringMethod: MosaicDitheringMethod = .floydSteinberg
    ) {
        self.mosaicSize = mosaicSize
        self.paletteID = paletteID
        self.part = part
        self.ditheringMethod = ditheringMethod
    }
}

struct GeneratedProjectArtifacts: Codable, Hashable, Sendable {
    let palette: [BrickColor]
    let grid: MosaicGrid
    let partRequirements: [PartRequirement]
    let buildPlan: BuildPlan?
}

/// Das Projektmodell fasst alle MVP-Artefakte in einer serialisierbaren Form zusammen.
struct BrickCanvasProject: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let name: String
    let lifecycle: ProjectLifecycle
    let sourceImage: SourceImageReference
    let cropRegion: CropRegion
    let configuration: MosaicConfiguration
    let generatedArtifacts: GeneratedProjectArtifacts?
    let createdAt: Date
    let updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        lifecycle: ProjectLifecycle,
        sourceImage: SourceImageReference,
        cropRegion: CropRegion,
        configuration: MosaicConfiguration,
        generatedArtifacts: GeneratedProjectArtifacts?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.lifecycle = lifecycle
        self.sourceImage = sourceImage
        self.cropRegion = cropRegion
        self.configuration = configuration
        self.generatedArtifacts = generatedArtifacts
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var isGenerated: Bool {
        generatedArtifacts != nil
    }
}
