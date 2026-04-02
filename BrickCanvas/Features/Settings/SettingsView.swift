import SwiftUI

struct SettingsView: View {
    @AppStorage(PaletteListMode.storageKey) private var paletteListModeRawValue = PaletteListMode.simple.rawValue
    @AppStorage(MosaicDitheringMethod.storageKey) private var ditheringMethodRawValue = MosaicDitheringMethod.ostromoukhov.rawValue
    @State private var palette: BrickPalette?
    @State private var paletteLoadingError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                ditheringMethodCard
                paletteModeCard
                paletteContent
            }
            .frame(maxWidth: 880, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Einstellungen")
        .task {
            await loadPaletteIfNeeded()
        }
    }

    private var selectedPaletteListMode: PaletteListMode {
        get { PaletteListMode(rawValue: paletteListModeRawValue) ?? .simple }
        nonmutating set { paletteListModeRawValue = newValue.rawValue }
    }

    private var selectedDitheringMethod: MosaicDitheringMethod {
        get { MosaicDitheringMethod(rawValue: ditheringMethodRawValue) ?? .ostromoukhov }
        nonmutating set { ditheringMethodRawValue = newValue.rawValue }
    }

    private var displayedColors: [BrickColor] {
        guard let palette else {
            return []
        }

        switch selectedPaletteListMode {
        case .simple:
            return palette.activeColors
        case .complete:
            return palette.colors
        }
    }

    private var basisColorCount: Int {
        palette?.activeColors.count ?? 0
    }

    private var rareColorCount: Int {
        guard let palette else {
            return 0
        }

        return palette.colors.count - palette.activeColors.count
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("APP")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.orange)

            Text("Rendering")
                .font(.largeTitle.weight(.bold))

            Text("Lege fest, wie BrickCanvas neue Mosaike standardmäßig auf die LEGO-Palette quantisiert und welche Farbliste dabei angeboten wird.")
                .foregroundStyle(.secondary)
        }
    }

    private var ditheringMethodCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Dithering")
                .font(.title3.weight(.semibold))

            Picker("Dithering", selection: $ditheringMethodRawValue) {
                ForEach(MosaicDitheringMethod.allCases) { method in
                    Text(method.title).tag(method.rawValue)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(MosaicDitheringMethod.allCases) { method in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: method == selectedDitheringMethod ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(method == selectedDitheringMethod ? .orange : .secondary)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(method.title)
                                .font(.headline)

                            Text(method.shortDescription)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text(method.detailDescription)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Text("Die Auswahl wird als Standard für neue Mosaik-Generierungen gespeichert. Ostromoukhov ist auf visuelle Qualität optimiert, Floyd-Steinberg bleibt als klassische Fallback-Methode verfügbar.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .settingsCardStyle()
    }

    private var paletteModeCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Farbliste")
                .font(.title3.weight(.semibold))

            Picker("Farbliste", selection: $paletteListModeRawValue) {
                ForEach(PaletteListMode.allCases) { mode in
                    Text(mode.title).tag(mode.rawValue)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(PaletteListMode.allCases) { mode in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: mode == selectedPaletteListMode ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(mode == selectedPaletteListMode ? .orange : .secondary)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(mode.title)
                                .font(.headline)

                            Text(mode.description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .animation(.default, value: selectedPaletteListMode)
        }
        .settingsCardStyle()
    }

    @ViewBuilder
    private var paletteContent: some View {
        if palette != nil {
            VStack(alignment: .leading, spacing: 20) {
                Text("Vorschau")
                    .font(.title3.weight(.semibold))

                HStack(spacing: 12) {
                    statCard(title: "Basisfarben", value: "\(basisColorCount)", tint: .orange.opacity(0.18))
                    statCard(title: "Seltene Farben", value: "\(rareColorCount)", tint: .blue.opacity(0.16))
                    statCard(title: "Aktuelle Liste", value: "\(displayedColors.count)", tint: .green.opacity(0.16))
                }

                Text("Die 12 Basisfarben orientieren sich an der Farbreferenz von 1000steine. In der vollständigen Ansicht werden zusätzlich alle seltenen Farben aus der importierten LEGO-Tabelle eingeblendet.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 150), spacing: 12)],
                    alignment: .leading,
                    spacing: 12
                ) {
                    ForEach(displayedColors) { color in
                        colorChip(for: color)
                    }
                }
            }
            .settingsCardStyle()
        } else if let paletteLoadingError {
            VStack(alignment: .leading, spacing: 12) {
                Label("Farbtabelle konnte nicht geladen werden", systemImage: "exclamationmark.triangle")
                    .font(.headline)

                Text(paletteLoadingError)
                    .foregroundStyle(.secondary)
            }
            .settingsCardStyle()
        } else {
            HStack(spacing: 12) {
                ProgressView()
                Text("Farbtabelle wird geladen …")
                    .foregroundStyle(.secondary)
            }
            .settingsCardStyle()
        }
    }

    private func statCard(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title2.weight(.bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tint)
        )
    }

    private func colorChip(for color: BrickColor) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(rgbColor: color.rgb))
                .frame(height: 56)
                .overlay(alignment: .topTrailing) {
                    Text(color.isActive ? "Basis" : "Selten")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(8)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(color.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)

                Text(color.rgb.hexString)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func loadPaletteIfNeeded() async {
        guard palette == nil, paletteLoadingError == nil else {
            return
        }

        do {
            let service = try BundledPaletteService()
            palette = try await service.palette(
                for: PaletteQuery(
                    paletteID: "mvp-default",
                    includeInactiveColors: true
                )
            )
        } catch {
            paletteLoadingError = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}

private extension View {
    func settingsCardStyle() -> some View {
        padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
    }
}

private extension Color {
    init(rgbColor: RGBColor) {
        self.init(
            red: Double(rgbColor.red) / 255.0,
            green: Double(rgbColor.green) / 255.0,
            blue: Double(rgbColor.blue) / 255.0
        )
    }
}
