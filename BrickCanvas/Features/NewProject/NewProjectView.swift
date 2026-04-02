import ImageIO
import PhotosUI
import SwiftUI

struct NewProjectView: View {
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var importedImage: ImportedImage?
    @State private var previewImage: CGImage?
    @State private var errorMessage: String?
    @State private var isImporting = false

    private let imageImportService = DefaultImageImportService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("IMPORT".uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.blue)

                    Text("Neues Projekt")
                        .font(.largeTitle.weight(.bold))

                    Text("Wähle ein Foto aus deiner Mediathek. Das Bild wird direkt geladen, in seiner Orientierung normalisiert und als Vorschau angezeigt.")
                        .foregroundStyle(.secondary)
                }

                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label("Foto aus Mediathek wählen", systemImage: "photo.on.rectangle.angled")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isImporting)

                if isImporting {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Bild wird importiert und ausgerichtet …")
                            .foregroundStyle(.secondary)
                    }
                }

                if let errorMessage {
                    ContentUnavailableView(
                        "Import fehlgeschlagen",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                }

                if let previewImage {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ausgewähltes Bild")
                            .font(.headline)

                        Image(decorative: previewImage, scale: 1)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(.blue.opacity(0.2), lineWidth: 1)
                            }

                        if let importedImage {
                            Text(detailText(for: importedImage))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else if isImporting == false {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nächster Schritt")
                            .font(.headline)
                            .foregroundStyle(.blue)

                        Text("Bildimport")
                            .font(.title2.weight(.semibold))

                        Text("Nach dem Import folgt der Zuschnitt. Kamera, Framing und weitere Optionen kommen später im Flow dazu.")
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Unterstützt gängige Bildformate aus der Fotobibliothek")
                            Text("Korrigiert gedrehte Fotos direkt beim Import")
                            Text("Zeigt Fehlerzustände ohne App-Abbruch")
                        }
                        .font(.body)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(.blue.opacity(0.08))
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Neues Projekt")
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                await importPhoto(from: newItem)
            }
        }
    }

    @MainActor
    private func importPhoto(from item: PhotosPickerItem?) async {
        guard let item else {
            return
        }

        isImporting = true
        errorMessage = nil

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw ServiceError.unavailable("Für das ausgewählte Foto konnten keine Bilddaten geladen werden.")
            }

            let supportedType = item.supportedContentTypes.first
            let filenameExtension = supportedType?.preferredFilenameExtension ?? "jpg"
            let request = ImageImportRequest(
                source: .photoLibrary,
                payload: ImageDataAsset(
                    data: data,
                    filename: "photo-library-import.\(filenameExtension)",
                    pixelWidth: 0,
                    pixelHeight: 0,
                    mimeType: supportedType?.preferredMIMEType ?? "image/jpeg"
                )
            )
            let result = try await imageImportService.importImage(request)

            importedImage = result.image
            previewImage = try makePreviewImage(from: result.image.asset.data)
        } catch {
            importedImage = nil
            previewImage = nil
            errorMessage = error.localizedDescription
        }

        isImporting = false
    }

    private func detailText(for image: ImportedImage) -> String {
        "\(image.asset.pixelWidth) × \(image.asset.pixelHeight) px · \(image.asset.mimeType) · Quelle: \(image.source.rawValue)"
    }

    private func makePreviewImage(from data: Data) throws -> CGImage {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw ServiceError.processingFailed("Das importierte Bild konnte nicht angezeigt werden.")
        }

        return image
    }
}

#Preview {
    NavigationStack {
        NewProjectView()
    }
}
