import Foundation

enum MosaicPreviewState: Equatable, Sendable {
    case idle
    case rendering
    case rendered(MosaicPreviewContent)
    case failed(String)
}

struct MosaicPreviewContent: Equatable, Sendable {
    let grid: MosaicGrid
    let palette: [BrickColor]
}
