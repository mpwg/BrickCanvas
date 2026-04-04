import ImageIO
import PhotosUI
import SwiftUI

struct NewProjectView: View {
    private static let minimumMosaicDimension = 16.0
    private static let maximumMosaicDimension = 128.0
    private static let defaultPaletteID = "mvp-default"

    @AppStorage(MosaicDitheringMethod.storageKey) private var ditheringMethodRawValue = MosaicDitheringMethod.jarvisJudiceNinke.rawValue
    @AppStorage(PaletteActivationStore.storageKey) private var paletteActivationStateRawValue = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var importedImage: ImportedImage?
    @State private var previewImage: CGImage?
    @State private var cropRegion: CropRegion?
    @State private var cropPreset: CropAspectPreset = .square
    @State private var mosaicSize: Double = 48
    @State private var mosaicPreviewState: MosaicPreviewState = .idle
    @State private var importState: NewProjectImportState = .idle
    @State private var importTask: Task<Void, Never>?

    private let imageImportService = DefaultImageImportService()
    private let paletteService = try! BundledPaletteService()
    private let mosaicGeneratorService = PackageBackedMosaicGeneratorService()

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

                    if case .importing(let step) = importState {
                        loadingCard(for: step)
                            .frame(maxWidth: pageWidth, alignment: .leading)
                    }

                    if case .failed(let presentation) = importState {
                        errorCard(presentation: presentation)
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

                        mosaicPreviewCard
                            .frame(maxWidth: pageWidth, alignment: .leading)
                    } else if importState.isRunning == false {
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
            startImport(from: newItem)
        }
        .task(id: mosaicPreviewTrigger) {
            await refreshMosaicPreview()
        }
        .onDisappear {
            cancelImport()
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
            .disabled(importState.isRunning)
        }
        .cardStyle()
    }

    private func loadingCard(for step: ImportProgressStep) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ProgressView()
                VStack(alignment: .leading, spacing: 4) {
                    Text(step.title)
                        .font(.headline)

                    Text(step.message)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }

            Button("Import abbrechen") {
                cancelImport()
            }
            .buttonStyle(.bordered)
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

    private func errorCard(presentation: ImportErrorPresentation) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(presentation.title, systemImage: "exclamationmark.triangle")
                .font(.title3.weight(.semibold))

            Text(presentation.message)
                .foregroundStyle(.secondary)

            Text(presentation.recoverySuggestion)
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button("Erneut versuchen") {
                    startImport(from: selectedPhotoItem)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedPhotoItem == nil)

                Button("Fehler ausblenden") {
                    importState = .idle
                }
                .buttonStyle(.bordered)
            }
        }
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

    @ViewBuilder
    private var mosaicPreviewCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("4. Mosaikvorschau")
                    .font(.title3.weight(.semibold))

                Text("Die Vorschau rendert bereits das quantisierte Raster. Du kannst hineinzoomen, verschieben und das Ergebnis sofort gegen Crop und Zielgröße prüfen.")
                    .foregroundStyle(.secondary)
            }

            switch mosaicPreviewState {
            case .idle:
                Label("Die Vorschau erscheint, sobald ein Zuschnitt verfügbar ist.", systemImage: "wand.and.stars")
                    .foregroundStyle(.secondary)

            case .rendering:
                VStack(alignment: .leading, spacing: 14) {
                    ProgressView()
                        .controlSize(.large)

                    Text("Mosaik wird neu berechnet …")
                        .font(.headline)

                    Text("Änderungen an Zuschnitt, Größe, aktiver Palette oder Dithering werden automatisch übernommen.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(.tertiarySystemGroupedBackground))
                )

            case let .rendered(content):
                MosaicPreviewView(
                    grid: content.grid,
                    palette: content.palette
                )
                .frame(height: 360)

                VStack(alignment: .leading, spacing: 10) {
                    Label(
                        "Raster \(content.grid.size.width) × \(content.grid.size.height) mit \(selectedDitheringMethod.title)",
                        systemImage: "sparkles.rectangle.stack"
                    )

                    Label("Doppeltippen setzt die Ansicht zurück. Das Gitter wird bei stärkerem Zoom bewusst scharf eingeblendet.", systemImage: "hand.draw")
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)

            case let .failed(message):
                VStack(alignment: .leading, spacing: 12) {
                    Label("Vorschau konnte nicht erzeugt werden", systemImage: "exclamationmark.triangle")
                        .font(.headline)

                    Text(message)
                        .foregroundStyle(.secondary)

                    Button("Erneut berechnen") {
                        Task {
                            await refreshMosaicPreview(force: true)
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(.tertiarySystemGroupedBackground))
                )
            }
        }
        .cardStyle(tint: .mint.opacity(0.08))
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

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(currentMosaicDimension) × \(currentMosaicDimension)")
                        .font(.title2.weight(.bold))

                    Spacer()

                    Text("\(currentMosaicGridSize.studCount) Noppen")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Slider(
                    value: Binding(
                        get: { mosaicSize },
                        set: { mosaicSize = snappedMosaicSize(for: $0) }
                    ),
                    in: Self.minimumMosaicDimension...Self.maximumMosaicDimension,
                    step: 1
                )
                .tint(.orange)
                .accessibilityLabel("Mosaikgröße")
                .accessibilityValue("\(currentMosaicDimension) mal \(currentMosaicDimension) Noppen")
                .overlay(alignment: .bottomLeading) {
                    GeometryReader { proxy in
                        let trackWidth = max(proxy.size.width - 28, 1)

                        ZStack(alignment: .leading) {
                            ForEach(MosaicSizePreset.allCases) { preset in
                                Capsule()
                                    .fill(currentMosaicDimension == preset.gridSize.width ? Color.orange : Color.secondary.opacity(0.45))
                                    .frame(width: 3, height: 10)
                                    .offset(
                                        x: markerOffset(
                                            for: Double(preset.gridSize.width),
                                            trackWidth: trackWidth
                                        ),
                                        y: 18
                                    )
                            }
                        }
                    }
                    .frame(height: 28)
                }

                HStack {
                    Text("\(Int(Self.minimumMosaicDimension))")
                    Spacer()
                    Text("\(Int(Self.maximumMosaicDimension))")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Text("Der Slider erlaubt alle Werte von 16 bis \(Int(Self.maximumMosaicDimension)). An den bisherigen Standardgrößen 24, 48 und 64 rastet er ein.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func startImport(from item: PhotosPickerItem?) {
        importTask?.cancel()

        guard let item else {
            importState = .idle
            return
        }

        importTask = Task {
            await importPhoto(from: item)
        }
    }

    private func cancelImport() {
        importTask?.cancel()
        importTask = nil
        importState = .idle
        mosaicPreviewState = .idle
    }

    @MainActor
    private func importPhoto(from item: PhotosPickerItem) async {
        importState = .importing(.requestingImageData)

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw ServiceError.unavailable("Für das ausgewählte Foto konnten keine Bilddaten geladen werden.")
            }
            try Task.checkCancellation()

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
            importState = .importing(.normalizingImage)
            let result = try await imageImportService.importImage(request)
            try Task.checkCancellation()

            importState = .importing(.preparingEditor)
            importedImage = result.image
            previewImage = try makePreviewImage(from: result.image.asset.data)
            cropRegion = nil
            cropPreset = .square
            mosaicSize = 48
            mosaicPreviewState = .idle
            importState = .idle
        } catch is CancellationError {
            importState = .idle
        } catch {
            importState = .failed(ImportErrorPresentation.from(error))
        }

        importTask = nil
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
        let size = currentMosaicGridSize

        if let cropRegion {
            let cropWidth = Int((Double(previewImage.width) * cropRegion.width).rounded())
            let cropHeight = Int((Double(previewImage.height) * cropRegion.height).rounded())
            return "Aktiver Zuschnitt \(cropWidth) × \(cropHeight) px -> Zielraster \(size.width) × \(size.height) Noppen (\(size.studCount) Positionen)"
        }

        return "Zielraster \(size.width) × \(size.height) Noppen (\(size.studCount) Positionen)"
    }

    private var mosaicPreviewTrigger: MosaicPreviewTrigger? {
        guard let importedImage, let cropRegion else {
            return nil
        }

        return MosaicPreviewTrigger(
            filename: importedImage.asset.filename,
            cropRegion: cropRegion,
            mosaicSize: currentMosaicGridSize,
            ditheringMethodRawValue: ditheringMethodRawValue,
            paletteActivationStateRawValue: paletteActivationStateRawValue
        )
    }

    private var selectedDitheringMethod: MosaicDitheringMethod {
        MosaicDitheringMethod(rawValue: ditheringMethodRawValue) ?? .jarvisJudiceNinke
    }

    private var currentMosaicDimension: Int {
        Int(mosaicSize.rounded())
    }

    private var currentMosaicGridSize: MosaicGridSize {
        try! MosaicGridSize(width: currentMosaicDimension, height: currentMosaicDimension)
    }

    private func snappedMosaicSize(for proposedValue: Double) -> Double {
        let roundedValue = proposedValue.rounded()
        let snapValues = MosaicSizePreset.allCases.map { Double($0.gridSize.width) }

        if let snapValue = snapValues.first(where: { abs($0 - roundedValue) <= 2 }) {
            return snapValue
        }

        return roundedValue
    }

    private func markerOffset(for value: Double, trackWidth: CGFloat) -> CGFloat {
        let clampedValue = min(max(value, Self.minimumMosaicDimension), Self.maximumMosaicDimension)
        let normalizedValue = (clampedValue - Self.minimumMosaicDimension) / (Self.maximumMosaicDimension - Self.minimumMosaicDimension)
        return trackWidth * normalizedValue + 14
    }

    @MainActor
    private func refreshMosaicPreview(force: Bool = false) async {
        guard let importedImage, let cropRegion else {
            mosaicPreviewState = .idle
            return
        }

        if force == false {
            do {
                try await Task.sleep(for: .milliseconds(180))
            } catch {
                return
            }
        }

        mosaicPreviewState = .rendering

        do {
            let palette = try await loadEffectivePalette()
            try Task.checkCancellation()

            let request = MosaicGenerationRequest(
                image: importedImage,
                cropRegion: cropRegion,
                configuration: MosaicConfiguration(
                    mosaicSize: currentMosaicGridSize,
                    paletteID: Self.defaultPaletteID,
                    part: .roundPlate1x1,
                    ditheringMethod: selectedDitheringMethod
                ),
                palette: palette
            )
            let result = try await mosaicGeneratorService.generateMosaic(from: request)
            try Task.checkCancellation()

            mosaicPreviewState = .rendered(
                MosaicPreviewContent(
                    grid: result.grid,
                    palette: palette.colors
                )
            )
        } catch is CancellationError {
            return
        } catch {
            mosaicPreviewState = .failed(error.localizedDescription)
        }
    }

    private func loadEffectivePalette() async throws -> BrickPalette {
        let basePalette = try await paletteService.palette(
            for: PaletteQuery(
                paletteID: Self.defaultPaletteID,
                includeInactiveColors: true
            )
        )
        let activeColorIDs = PaletteActivationStore.activeColorIDs(
            from: paletteActivationStateRawValue,
            for: basePalette
        )

        return try await paletteService.palette(
            for: PaletteQuery(
                paletteID: Self.defaultPaletteID,
                activeColorIDs: activeColorIDs
            )
        )
    }

    private func makePreviewImage(from data: Data) throws -> CGImage {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw ServiceError.processingFailed("Das importierte Bild konnte nicht angezeigt werden.")
        }

        return image
    }
}

private struct MosaicPreviewTrigger: Hashable {
    let filename: String
    let cropRegion: CropRegion
    let mosaicSize: MosaicGridSize
    let ditheringMethodRawValue: String
    let paletteActivationStateRawValue: String
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
