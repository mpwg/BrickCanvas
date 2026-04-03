import SwiftUI

struct SettingsView: View {
    @AppStorage(PaletteListMode.storageKey) private var paletteListModeRawValue = PaletteListMode.simple.rawValue
    @AppStorage(MosaicDitheringMethod.storageKey) private var ditheringMethodRawValue = MosaicDitheringMethod.jarvisJudiceNinke.rawValue
    @AppStorage(PaletteActivationStore.storageKey) private var paletteActivationStateRawValue = ""
    @State private var palette: BrickPalette?
    @State private var paletteLoadingError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                ditheringMethodCard
                paletteModeCard
                paletteContent
                packageCard
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
        get {
            guard let palette else {
                return PaletteListMode(rawValue: paletteListModeRawValue) ?? .simple
            }

            let activeColorIDs = PaletteActivationStore.activeColorIDs(from: paletteActivationStateRawValue, for: palette)
            if activeColorIDs == palette.activeColorIDs {
                return .simple
            }

            if activeColorIDs == palette.allColorIDs {
                return .complete
            }

            return .custom
        }
        nonmutating set {
            paletteListModeRawValue = newValue.rawValue
            applyPalettePreset(newValue)
        }
    }

    private var selectedDitheringMethod: MosaicDitheringMethod {
        get { MosaicDitheringMethod(rawValue: ditheringMethodRawValue) ?? .jarvisJudiceNinke }
        nonmutating set { ditheringMethodRawValue = newValue.rawValue }
    }

    private let packages: [PackageReference] = [
        PackageReference(
            name: "DitheringEngine",
            version: "1.10.0",
            integration: "Swift Package via GitHub",
            license: "MIT",
            sourceURL: "https://github.com/Eskils/DitheringEngine",
            usage: "Stellt die auswählbaren Dithering-Verfahren für die Mosaik-Generierung bereit."
        )
    ]

    private var basePaletteColorCount: Int {
        palette?.activeColors.count ?? 0
    }

    private var fullPaletteColorCount: Int {
        palette?.colors.count ?? 0
    }

    private var activePaletteColorCount: Int {
        effectivePalette?.activeColors.count ?? 0
    }

    private var inactivePaletteColorCount: Int {
        max(fullPaletteColorCount - activePaletteColorCount, 0)
    }

    private var effectivePalette: BrickPalette? {
        guard let palette else {
            return nil
        }

        let activeColorIDs = PaletteActivationStore.activeColorIDs(from: paletteActivationStateRawValue, for: palette)
        return palette.applyingActiveColorIDs(activeColorIDs)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("APP")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.orange)

            Text("Rendering")
                .font(.largeTitle.weight(.bold))

            Text("Lege fest, wie BrickCanvas neue Mosaike standardmäßig auf die LEGO-Palette quantisiert, welche Farbliste angeboten wird und welche Swift Packages im Projekt verwendet werden.")
                .foregroundStyle(.secondary)
        }
    }

    private var ditheringMethodCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Dithering")
                .font(.title3.weight(.semibold))

            VStack(alignment: .leading, spacing: 10) {
                ForEach(MosaicDitheringMethod.allCases) { method in
                    Button {
                        selectedDitheringMethod = method
                    } label: {
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
                    .buttonStyle(.plain)
                }
            }

            Text("Die Auswahl wird als Standard für neue Mosaik-Generierungen gespeichert. Jarvis-Judice-Ninke ist hier der sinnvolle Qualitäts-Default, Floyd-Steinberg bleibt als klassische Alternative verfügbar.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .settingsCardStyle()
    }

    private var paletteModeCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Aktive Farben")
                .font(.title3.weight(.semibold))

            Picker("Aktivierungsmodus", selection: Binding(
                get: { selectedPaletteListMode },
                set: { selectedPaletteListMode = $0 }
            )) {
                ForEach(PaletteListMode.allCases) { mode in
                    Text(mode.title).tag(mode)
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

            Text("Du kannst jederzeit einzelne Farben direkt in der Liste umschalten. Das Dithering verwendet ausschließlich die hier aktiven Farben.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .settingsCardStyle()
    }

    @ViewBuilder
    private var paletteContent: some View {
        if let effectivePalette {
            VStack(alignment: .leading, spacing: 20) {
                Text("Farbaktivierung")
                    .font(.title3.weight(.semibold))

                HStack(spacing: 12) {
                    statCard(title: "Basisfarben", value: "\(basePaletteColorCount)", tint: .orange.opacity(0.18))
                    statCard(title: "Aktiv", value: "\(activePaletteColorCount)", tint: .green.opacity(0.16))
                    statCard(title: "Inaktiv", value: "\(inactivePaletteColorCount)", tint: .blue.opacity(0.16))
                }

                Text("Die Basisfarben orientieren sich an der Farbreferenz von 1000steine. Darüber hinaus kannst du jede importierte LEGO-Farbe einzeln aktivieren oder deaktivieren.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 150), spacing: 12)],
                    alignment: .leading,
                    spacing: 12
                ) {
                    ForEach(effectivePalette.colors) { color in
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

    private var packageCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Swift Packages")
                .font(.title3.weight(.semibold))

            ForEach(packages) { package in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(package.name)
                            .font(.headline)

                        Spacer()

                        Text(package.version)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }

                    Text(package.usage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("Lizenz: \(package.license)")
                        .font(.footnote)

                    Text("Einbindung: \(package.integration)")
                        .font(.footnote)

                    Text(package.sourceURL)
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(.tertiarySystemGroupedBackground))
                )
            }
        }
        .settingsCardStyle()
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
        let isDefaultActive = palette?.activeColorIDs.contains(color.id) ?? false

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(rgbColor: color.rgb))
                    .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text(color.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)

                    Text(color.rgb.hexString)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)

                    Text(isDefaultActive ? "Basisfarbe" : "Erweiterungsfarbe")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(isDefaultActive ? .orange : .secondary)
                }

                Spacer(minLength: 0)
            }

            Toggle(isOn: Binding(
                get: { color.isActive },
                set: { _ in toggleColor(color.id) }
            )) {
                Text(color.isActive ? "Aktiv für Dithering" : "Nicht aktiv")
                    .font(.footnote.weight(.medium))
            }
            .toggleStyle(.switch)
            .disabled(color.isActive && activePaletteColorCount <= 1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(color.isActive ? Color(.secondarySystemGroupedBackground) : Color(.tertiarySystemGroupedBackground))
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

    private func applyPalettePreset(_ preset: PaletteListMode) {
        guard let palette else {
            return
        }

        let activeColorIDs: Set<String>
        switch preset {
        case .simple:
            activeColorIDs = palette.activeColorIDs
        case .complete:
            activeColorIDs = palette.allColorIDs
        case .custom:
            return
        }

        paletteActivationStateRawValue = PaletteActivationStore.save(
            activeColorIDs: activeColorIDs,
            for: palette.id,
            in: paletteActivationStateRawValue
        )
    }

    private func toggleColor(_ colorID: String) {
        guard let palette else {
            return
        }

        var activeColorIDs = PaletteActivationStore.activeColorIDs(from: paletteActivationStateRawValue, for: palette)

        if activeColorIDs.contains(colorID) {
            guard activeColorIDs.count > 1 else {
                return
            }

            activeColorIDs.remove(colorID)
        } else {
            activeColorIDs.insert(colorID)
        }

        paletteActivationStateRawValue = PaletteActivationStore.save(
            activeColorIDs: activeColorIDs,
            for: palette.id,
            in: paletteActivationStateRawValue
        )
        paletteListModeRawValue = PaletteListMode.custom.rawValue
    }
}

private struct PackageReference: Identifiable {
    let name: String
    let version: String
    let integration: String
    let license: String
    let sourceURL: String
    let usage: String

    var id: String { name }
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
