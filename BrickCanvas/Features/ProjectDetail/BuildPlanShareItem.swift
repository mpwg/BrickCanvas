import CoreTransferable
import Foundation
import UniformTypeIdentifiers

struct BuildPlanShareItem: Transferable {
    let project: BrickCanvasProject

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .png) { item in
            let artifact = try DefaultExportEngine().exportBuildPlanImage(for: item.project)
            let directoryURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString, isDirectory: true)

            try FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )

            let url = directoryURL.appendingPathComponent(artifact.filename)

            try artifact.data.write(to: url, options: .atomic)
            return SentTransferredFile(url, allowAccessingOriginalFile: false)
        }
    }
}
