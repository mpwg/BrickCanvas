import SwiftUI

struct ProjectDetailView: View {
    let state: ProjectPartSummaryScreenState

    init(state: ProjectPartSummaryScreenState = .loaded(ProjectPartSummaryContent(project: PreviewProjects.generated))) {
        self.state = state
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                switch state {
                case let .loaded(content):
                    ProjectPartSummaryHero(content: content)
                    ProjectPartSummaryStats(content: content)
                    ProjectPartSummaryList(content: content)
                case let .empty(configuration):
                    ProjectPartSummaryEmptyState(configuration: configuration)
                case let .error(configuration):
                    ProjectPartSummaryErrorState(configuration: configuration)
                }
            }
            .frame(maxWidth: 920, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .background(ProjectPartSummaryBackground())
        .navigationTitle("Projekte")
    }
}

enum ProjectPartSummaryScreenState: Hashable, Sendable {
    case loaded(ProjectPartSummaryContent)
    case empty(ProjectPartSummaryEmptyConfiguration)
    case error(ProjectPartSummaryErrorConfiguration)

    init(project: BrickCanvasProject) {
        guard let artifacts = project.generatedArtifacts else {
            self = .empty(
                ProjectPartSummaryEmptyConfiguration(
                    title: "Noch keine Teileliste",
                    message: "Dieses Projekt wurde bereits angelegt, aber die Mosaik-Generierung hat noch keine Teileanforderungen erzeugt.",
                    systemImage: "shippingbox"
                )
            )
            return
        }

        guard artifacts.partRequirements.isEmpty == false else {
            self = .empty(
                ProjectPartSummaryEmptyConfiguration(
                    title: "Keine Teile erforderlich",
                    message: "Für dieses Projekt liegen aktuell keine Teileanforderungen vor. Prüfe die Generierung oder die gewählte Konfiguration.",
                    systemImage: "tray"
                )
            )
            return
        }

        self = .loaded(ProjectPartSummaryContent(project: project))
    }
}

struct ProjectPartSummaryEmptyConfiguration: Hashable, Sendable {
    let title: String
    let message: String
    let systemImage: String
}

struct ProjectPartSummaryErrorConfiguration: Hashable, Sendable {
    let title: String
    let message: String
    let systemImage: String
}

struct ProjectPartSummaryContent: Hashable, Sendable {
    let projectName: String
    let partName: String
    let gridDescription: String
    let totalPieces: Int
    let distinctColorCount: Int
    let updatedAtText: String
    let rows: [ProjectPartSummaryRow]

    init(project: BrickCanvasProject) {
        let paletteByID = Dictionary(
            uniqueKeysWithValues: (project.generatedArtifacts?.palette ?? []).map { ($0.id, $0) }
        )
        let requirements = project.generatedArtifacts?.partRequirements ?? []
        let formatter = DateFormatter.projectPartSummaryTimestamp

        projectName = project.name
        partName = project.configuration.part.displayName
        gridDescription = "\(project.configuration.mosaicSize.width) × \(project.configuration.mosaicSize.height) Noppen"
        totalPieces = requirements.reduce(into: 0) { partialResult, requirement in
            partialResult += requirement.quantity
        }
        distinctColorCount = requirements.count
        updatedAtText = formatter.string(from: project.updatedAt)
        rows = requirements
            .map { requirement in
                let paletteColor = paletteByID[requirement.colorID]
                return ProjectPartSummaryRow(
                    colorName: paletteColor?.name ?? requirement.colorID.humanizedColorID,
                    colorSubtitle: paletteColor?.rgb.hexString ?? requirement.colorID.uppercased(),
                    swatchColor: paletteColor?.rgb ?? RGBColor(red: 142, green: 142, blue: 147),
                    quantity: requirement.quantity
                )
            }
            .sorted(using: [
                KeyPathComparator(\.quantity, order: .reverse),
                KeyPathComparator(\.colorName, comparator: .localizedStandard)
            ])
    }
}

struct ProjectPartSummaryRow: Hashable, Sendable, Identifiable {
    let colorName: String
    let colorSubtitle: String
    let swatchColor: RGBColor
    let quantity: Int

    var id: String {
        "\(colorName)-\(quantity)"
    }
}

private struct ProjectPartSummaryHero: View {
    let content: ProjectPartSummaryContent

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("TEILEÜBERSICHT")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.78))

            VStack(alignment: .leading, spacing: 10) {
                Text(content.projectName)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                Text("Alle benötigten Teile für dein Mosaik auf einen Blick, inklusive Farbverteilung, Gesamtmenge und Projektkontext.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.86))
            }

            HStack(spacing: 12) {
                summaryPill(title: content.partName, systemImage: "square.grid.3x3.fill")
                summaryPill(title: content.gridDescription, systemImage: "rectangle.grid.2x2")
                summaryPill(title: "Aktualisiert \(content.updatedAtText)", systemImage: "clock")
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.13, green: 0.22, blue: 0.34),
                            Color(red: 0.18, green: 0.52, blue: 0.58),
                            Color(red: 0.86, green: 0.47, blue: 0.27)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(.white.opacity(0.16))
                        .frame(width: 180, height: 180)
                        .offset(x: 48, y: -64)
                }
        )
    }

    private func summaryPill(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.white.opacity(0.16), in: Capsule())
    }
}

private struct ProjectPartSummaryStats: View {
    let content: ProjectPartSummaryContent

    var body: some View {
        HStack(spacing: 12) {
            statCard(
                title: "Gesamtteile",
                value: "\(content.totalPieces)",
                detail: "Alle Noppen im finalen Raster",
                tint: Color(red: 0.97, green: 0.63, blue: 0.23)
            )
            statCard(
                title: "Farben",
                value: "\(content.distinctColorCount)",
                detail: "Unterschiedliche Farbpositionen",
                tint: Color(red: 0.19, green: 0.65, blue: 0.56)
            )
            statCard(
                title: "Bauteil",
                value: content.partName,
                detail: "Einheitliche Teilebasis",
                tint: Color(red: 0.21, green: 0.45, blue: 0.85)
            )
        }
    }

    private func statCard(title: String, value: String, detail: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)

            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(tint.opacity(0.24), lineWidth: 1)
                )
        )
    }
}

private struct ProjectPartSummaryList: View {
    let content: ProjectPartSummaryContent

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Teileliste")
                        .font(.title3.weight(.semibold))

                    Text("Sortiert nach benötigter Menge, damit die wichtigsten Farben sofort sichtbar sind.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 16)

                Text("\(content.totalPieces) Teile")
                    .font(.headline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
            }

            LazyVStack(spacing: 12) {
                ForEach(content.rows) { row in
                    ProjectPartSummaryListRow(row: row)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

private struct ProjectPartSummaryListRow: View {
    let row: ProjectPartSummaryRow

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(rgbColor: row.swatchColor))

                Circle()
                    .strokeBorder(.white.opacity(0.72), lineWidth: 2)
            }
            .frame(width: 46, height: 46)
            .shadow(color: .black.opacity(0.08), radius: 10, y: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(row.colorName)
                    .font(.headline)

                Text(row.colorSubtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(row.quantity)")
                    .font(.system(.title3, design: .rounded, weight: .bold))

                Text(row.quantity == 1 ? "Teil" : "Teile")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.systemBackground))
        )
    }
}

private struct ProjectPartSummaryEmptyState: View {
    let configuration: ProjectPartSummaryEmptyConfiguration

    var body: some View {
        stateCard(
            title: configuration.title,
            message: configuration.message,
            systemImage: configuration.systemImage,
            tint: Color(red: 0.93, green: 0.58, blue: 0.21)
        )
    }
}

private struct ProjectPartSummaryErrorState: View {
    let configuration: ProjectPartSummaryErrorConfiguration

    var body: some View {
        stateCard(
            title: configuration.title,
            message: configuration.message,
            systemImage: configuration.systemImage,
            tint: Color(red: 0.79, green: 0.24, blue: 0.24)
        )
    }

    private func stateCard(title: String, message: String, systemImage: String, tint: Color) -> some View {
        ProjectPartSummaryStateCard(title: title, message: message, systemImage: systemImage, tint: tint)
    }
}

private struct ProjectPartSummaryStateCard: View {
    let title: String
    let message: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 56, height: 56)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.title2.weight(.bold))

                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, minHeight: 260, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

private struct ProjectPartSummaryBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(.systemGroupedBackground),
                Color(red: 0.95, green: 0.97, blue: 0.99)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

private extension ProjectPartSummaryEmptyState {
    func stateCard(title: String, message: String, systemImage: String, tint: Color) -> some View {
        ProjectPartSummaryStateCard(title: title, message: message, systemImage: systemImage, tint: tint)
    }
}

private extension BrickPart {
    var displayName: String {
        switch self {
        case .roundPlate1x1:
            "Runde Platte 1×1"
        case .squarePlate1x1:
            "Quadratische Platte 1×1"
        case .tile1x1:
            "Fliese 1×1"
        }
    }
}

private extension String {
    var humanizedColorID: String {
        split(separator: "-")
            .map { segment in
                segment.prefix(1).uppercased() + segment.dropFirst()
            }
            .joined(separator: " ")
    }
}

private extension DateFormatter {
    static let projectPartSummaryTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_AT")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
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

#Preview("Teileübersicht") {
    NavigationStack {
        ProjectDetailView(state: .loaded(ProjectPartSummaryContent(project: PreviewProjects.generated)))
    }
}

#Preview("Leer") {
    NavigationStack {
        ProjectDetailView(state: .empty(
            ProjectPartSummaryEmptyConfiguration(
                title: "Noch keine Teileliste",
                message: "Die Teileplanung erscheint hier, sobald ein Mosaik erfolgreich generiert wurde.",
                systemImage: "shippingbox"
            )
        ))
    }
}

#Preview("Fehler") {
    NavigationStack {
        ProjectDetailView(state: .error(
            ProjectPartSummaryErrorConfiguration(
                title: "Teileliste konnte nicht geladen werden",
                message: "Die Projektartefakte sind unvollständig oder beschädigt. Lade das Projekt erneut oder generiere es neu.",
                systemImage: "exclamationmark.triangle"
            )
        ))
    }
}
