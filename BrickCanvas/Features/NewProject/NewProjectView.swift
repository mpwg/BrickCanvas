import ImageIO
import PhotosUI
import SwiftUI

struct NewProjectView: View {
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var importedImage: ImportedImage?
    @State private var previewImage: CGImage?
    @State private var cropRegion: CropRegion?
    @State private var cropPreset: CropAspectPreset = .square
    @State private var mosaicSizePreset: MosaicSizePreset = .medium48x48
    @State private var errorMessage: String?
    @State private var isImporting = false

    private let imageImportService = DefaultImageImportService()
    private let imageCropService = DefaultImageCropService()

    var body: some View {
        GeometryReader { proxy in
            let pageWidth = min(max(proxy.size.width - 32, 320), 860)
            let cardInnerWidth = max(pageWidth - 48, 272)
            let editorWidth = min(cardInnerWidth, 720)
            let editorHeight = cropEditorHeight(for: editorWidth)

            ScrollView {
                VStack(spacing: 24) {
                    pageHeader
                        .frame(maxWidth: pageWidth, alignment: .leading)

                    importCard
                        .frame(maxWidth: pageWidth, alignment: .leading)

                    if let errorMessage {
                        errorCard(message: errorMessage)
                            .frame(maxWidth: pageWidth, alignment: .leading)
                    }

                    if isImporting {
                        loadingCard
                            .frame(maxWidth: pageWidth, alignment: .leading)
                    }

                    if let previewImage {
                        cropWorkspaceCard(
                            previewImage: previewImage,
                            editorWidth: editorWidth,
                            editorHeight: editorHeight
                        )
                        .frame(maxWidth: pageWidth, alignment: .leading)

                        mosaicConfigurationCard(previewImage: previewImage)
                            .frame(maxWidth: pageWidth, alignment: .leading)
                    } else if isImporting == false {
                        emptyStateCard
                            .frame(maxWidth: pageWidth, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Neues Projekt")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                await importPhoto(from: newItem)
            }
        }
    }

    private var pageHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("IMPORT".uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.blue)

            Text("Neues Projekt")
                .font(.largeTitle.weight(.bold))

            Text("Importiere ein Foto und richte es direkt für dein Mosaik aus.")
                .foregroundStyle(.secondary)
        }
    }

    private var importCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("1. Bild auswählen")
                .font(.title3.weight(.semibold))

            Text("Lade ein Foto aus deiner Mediathek. Die Orientierung wird beim Import normalisiert, damit der Zuschnitt stabil bleibt.")
                .foregroundStyle(.secondary)

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
        }
        .cardStyle()
    }

    private var loadingCard: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text("Bild wird importiert und ausgerichtet …")
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .cardStyle()
    }

    private var emptyStateCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("2. Framing")
                .font(.title3.weight(.semibold))

            Text("Nach dem Import erscheint hier der Editor mit Seitenverhältnis-Auswahl und den Eckdaten des aktiven Zuschnitts.")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                Text("Quadrat für LEGO-Art ist direkt verfügbar")
                Text("Zusätzliche Modi: 4:5, 16:9 und Original")
                Text("Pan und Zoom wirken direkt im Bild unter dem Crop-Rahmen")
            }
            .font(.body)
        }
        .cardStyle(tint: .blue.opacity(0.08))
    }

    private func errorCard(message: String) -> some View {
        ContentUnavailableView(
            "Import fehlgeschlagen",
            systemImage: "exclamationmark.triangle",
            description: Text(message)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func cropWorkspaceCard(
        previewImage: CGImage,
        editorWidth: CGFloat,
        editorHeight: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("2. Zuschnitt und Framing")
                    .font(.title3.weight(.semibold))

                Text("Das Bild bleibt in einer festen Arbeitsfläche. Darüber liegt nur der Crop-Rahmen des gewählten Formats.")
                    .foregroundStyle(.secondary)
            }

            Text("Zoomen und Verschieben wirken direkt im Bild. Beim Wechsel des Formats bleibt das Motiv an derselben Position, und nur der Rahmen ändert sich.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            aspectPresetPicker

            CropEditorView(
                image: previewImage,
                aspectPreset: cropPreset
            ) { layout in
                cropRegion = layout.cropRegion
            }
            .id(importedImage?.asset.filename ?? "crop-editor")
            .frame(width: editorWidth, height: editorHeight)
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 10) {
                Label(cropPreset.accessibilityLabel, systemImage: "aspectratio")

                if let importedImage {
                    Label(detailText(for: importedImage), systemImage: "photo")
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let cropRegion {
                    Label(cropDescription(for: cropRegion, image: previewImage), systemImage: "crop")
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .cardStyle()
    }

    private func mosaicConfigurationCard(previewImage: CGImage) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("3. Mosaikgröße")
                    .font(.title3.weight(.semibold))

                Text("Die gewählte Größe definiert das Zielraster für die spätere Generierung. Größere Raster liefern mehr Detail, benötigen aber entsprechend mehr Einzelsteine.")
                    .foregroundStyle(.secondary)
            }

            mosaicSizePicker

            VStack(alignment: .leading, spacing: 10) {
                Label(outputResolutionDescription(previewImage: previewImage), systemImage: "square.grid.3x3.fill")
                    .fixedSize(horizontal: false, vertical: true)

                if cropPreset != .square {
                    Label("Die aktuellen Größen-Presets sind quadratisch. Für ein unverzerrtes Ergebnis ist ein quadratischer Zuschnitt empfohlen.", systemImage: "info.circle")
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .cardStyle(tint: .orange.opacity(0.08))
    }

    private var aspectPresetPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Seitenverhältnis")
                .font(.subheadline.weight(.semibold))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(CropAspectPreset.allCases) { preset in
                        Button {
                            cropPreset = preset
                        } label: {
                            Text(preset.title)
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(cropPreset == preset ? Color.blue : Color(.secondarySystemBackground))
                                )
                                .foregroundStyle(cropPreset == preset ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(preset.accessibilityLabel)
                    }
                }
            }
        }
    }

    private var mosaicSizePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Zielgröße")
                .font(.subheadline.weight(.semibold))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(MosaicSizePreset.allCases) { preset in
                        Button {
                            mosaicSizePreset = preset
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(preset.title)
                                    .font(.headline.weight(.semibold))

                                Text(preset.subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(mosaicSizePreset == preset ? Color.white.opacity(0.88) : Color.secondary)
                            }
                            .frame(width: 140, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(mosaicSizePreset == preset ? Color.orange : Color(.secondarySystemBackground))
                            )
                            .foregroundStyle(mosaicSizePreset == preset ? Color.white : Color.primary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(preset.accessibilityLabel)
                    }
                }
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
            cropRegion = nil
            cropPreset = .square
            mosaicSizePreset = .medium48x48
        } catch {
            importedImage = nil
            previewImage = nil
            cropRegion = nil
            errorMessage = error.localizedDescription
        }

        isImporting = false
    }

    private func detailText(for image: ImportedImage) -> String {
        "\(image.asset.pixelWidth) × \(image.asset.pixelHeight) px · \(image.asset.mimeType) · Quelle: \(image.source.rawValue)"
    }

    private func cropDescription(for region: CropRegion, image: CGImage) -> String {
        let width = Int((Double(image.width) * region.width).rounded())
        let height = Int((Double(image.height) * region.height).rounded())
        return "\(width) × \(height) px · Ursprung \(Int((region.originX * 100).rounded())) % / \(Int((region.originY * 100).rounded())) %"
    }

    private func cropEditorHeight(for width: CGFloat) -> CGFloat {
        let ratio = cropPreset.aspectRatio(for: CGSize(
            width: CGFloat(previewImage?.width ?? 1),
            height: CGFloat(previewImage?.height ?? 1)
        ))
        return min(width / max(ratio, 0.1), 520)
    }

    private func outputResolutionDescription(previewImage: CGImage) -> String {
        let size = mosaicSizePreset.gridSize

        if let cropRegion {
            let cropWidth = Int((Double(previewImage.width) * cropRegion.width).rounded())
            let cropHeight = Int((Double(previewImage.height) * cropRegion.height).rounded())
            return "Aktiver Zuschnitt \(cropWidth) × \(cropHeight) px -> Zielraster \(size.width) × \(size.height) Noppen (\(size.studCount) Positionen)"
        }

        return "Zielraster \(size.width) × \(size.height) Noppen (\(size.studCount) Positionen)"
    }

    private func makePreviewImage(from data: Data) throws -> CGImage {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw ServiceError.processingFailed("Das importierte Bild konnte nicht angezeigt werden.")
        }

        return image
    }
}

private extension View {
    func cardStyle(tint: Color = Color(.secondarySystemGroupedBackground)) -> some View {
        self
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(tint)
            )
    }
}

#Preview {
    NavigationStack {
        NewProjectView()
    }
}
