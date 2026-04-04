import CoreGraphics
import SwiftUI

struct ProjectDetailView: View {
    let state: ProjectDetailScreenState

    init(state: ProjectDetailScreenState = .loaded(ProjectDetailContent(project: PreviewProjects.generated))) {
        self.state = state
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                switch state {
                case let .loaded(content):
                    ProjectDetailHero(content: content)
                    ProjectDetailBuildPlanSection(content: content)
                    ProjectDetailStats(content: content)
                    ProjectDetailPartsList(content: content)
                case let .empty(configuration):
                    ProjectDetailEmptyState(configuration: configuration)
                case let .error(configuration):
                    ProjectDetailErrorState(configuration: configuration)
                }
            }
            .frame(maxWidth: 1_040, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .background(ProjectDetailBackground())
        .navigationTitle("Projekte")
    }
}

enum ProjectDetailScreenState: Hashable, Sendable {
    case loaded(ProjectDetailContent)
    case empty(ProjectDetailEmptyConfiguration)
    case error(ProjectDetailErrorConfiguration)

    init(project: BrickCanvasProject) {
        guard let artifacts = project.generatedArtifacts else {
            self = .empty(
                ProjectDetailEmptyConfiguration(
                    title: "Noch kein generiertes Projekt",
                    message: "Dieses Projekt wurde bereits angelegt, aber die Mosaik-Generierung hat noch keine Artefakte erzeugt.",
                    systemImage: "shippingbox"
                )
            )
            return
        }

        guard artifacts.partRequirements.isEmpty == false else {
            self = .empty(
                ProjectDetailEmptyConfiguration(
                    title: "Keine Teile erforderlich",
                    message: "Für dieses Projekt liegen aktuell keine Teileanforderungen vor. Prüfe die Generierung oder die gewählte Konfiguration.",
                    systemImage: "tray"
                )
            )
            return
        }

        self = .loaded(ProjectDetailContent(project: project))
    }
}

struct ProjectDetailEmptyConfiguration: Hashable, Sendable {
    let title: String
    let message: String
    let systemImage: String
}

struct ProjectDetailErrorConfiguration: Hashable, Sendable {
    let title: String
    let message: String
    let systemImage: String
}

struct ProjectDetailContent: Hashable, Sendable {
    let project: BrickCanvasProject
    let projectName: String
    let partName: String
    let gridDescription: String
    let totalPieces: Int
    let distinctColorCount: Int
    let updatedAtText: String
    let buildPlanDocument: BuildPlanRenderDocument?
    let rows: [ProjectDetailPartRow]

    init(project: BrickCanvasProject) {
        let paletteByID = Dictionary(
            uniqueKeysWithValues: (project.generatedArtifacts?.palette ?? []).map { ($0.id, $0) }
        )
        let requirements = project.generatedArtifacts?.partRequirements ?? []
        let formatter = DateFormatter.projectDetailTimestamp

        self.project = project
        projectName = project.name
        partName = project.configuration.part.displayName
        gridDescription = "\(project.configuration.mosaicSize.width) × \(project.configuration.mosaicSize.height) Noppen"
        totalPieces = requirements.reduce(into: 0) { partialResult, requirement in
            partialResult += requirement.quantity
        }
        distinctColorCount = requirements.count
        updatedAtText = formatter.string(from: project.updatedAt)
        buildPlanDocument = BuildPlanRenderDocument(project: project)
        rows = requirements
            .map { requirement in
                let paletteColor = paletteByID[requirement.colorID]
                return ProjectDetailPartRow(
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

struct ProjectDetailPartRow: Hashable, Sendable, Identifiable {
    let colorName: String
    let colorSubtitle: String
    let swatchColor: RGBColor
    let quantity: Int

    var id: String {
        "\(colorName)-\(quantity)"
    }
}

private struct ProjectDetailHero: View {
    let content: ProjectDetailContent

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("BAUPLAN & TEILE")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))

            VStack(alignment: .leading, spacing: 10) {
                Text(content.projectName)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                Text("LEGO-Art-inspirierter Vollraster-Bauplan mit nummerierter Farblegende, Koordinaten und kompletter Teileliste auf einer Projektseite.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.86))
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    summaryPill(title: content.partName, systemImage: "square.grid.3x3.fill")
                    summaryPill(title: content.gridDescription, systemImage: "rectangle.grid.2x2")
                    summaryPill(title: "Aktualisiert \(content.updatedAtText)", systemImage: "clock")
                }

                VStack(alignment: .leading, spacing: 10) {
                    summaryPill(title: content.partName, systemImage: "square.grid.3x3.fill")
                    summaryPill(title: content.gridDescription, systemImage: "rectangle.grid.2x2")
                    summaryPill(title: "Aktualisiert \(content.updatedAtText)", systemImage: "clock")
                }
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.11, green: 0.17, blue: 0.25),
                            Color(red: 0.15, green: 0.42, blue: 0.46),
                            Color(red: 0.85, green: 0.53, blue: 0.23)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(.white.opacity(0.14))
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

private struct ProjectDetailBuildPlanSection: View {
    let content: ProjectDetailContent

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Bauplan")
                        .font(.title3.weight(.semibold))

                    Text("Der Plan orientiert sich am LEGO-Art-Stil: dunkle Grundplatte, nummerierte Noppen, klare Achsen und eine kompakte Farblegende.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                if content.buildPlanDocument != nil {
                    ShareLink(
                        item: BuildPlanShareItem(project: content.project),
                        preview: SharePreview("\(content.projectName) Bauplan")
                    ) {
                        Label("PNG teilen", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }

            if let buildPlanDocument = content.buildPlanDocument {
                ViewThatFits {
                    ProjectBuildPlanImage(document: buildPlanDocument, configuration: .projectDetailWide)
                        .frame(minWidth: 760)

                    ProjectBuildPlanImage(document: buildPlanDocument, configuration: .projectDetailCompact)
                }
            } else {
                ProjectDetailInlineStateCard(
                    title: "Bauplan noch nicht verfügbar",
                    message: "Die Teileliste ist bereits vorhanden, aber für dieses Projekt wurde noch kein renderbarer Bauplan erzeugt.",
                    systemImage: "square.grid.3x3",
                    tint: Color(red: 0.88, green: 0.62, blue: 0.24)
                )
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

private struct ProjectBuildPlanImage: View {
    let document: BuildPlanRenderDocument
    let configuration: BuildPlanRasterizationConfiguration

    @State private var rasterizedImage: CGImage?
    @State private var renderError: String?

    private var aspectRatio: CGFloat {
        let canvasSize = BuildPlanRasterizer.canvasSize(
            for: document,
            configuration: configuration
        )

        return canvasSize.width / max(canvasSize.height, 1)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(red: 0.05, green: 0.08, blue: 0.12))

            if let rasterizedImage {
                Image(decorative: rasterizedImage, scale: 1)
                    .resizable()
                    .interpolation(.none)
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(10)
            } else if let renderError {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Bauplan konnte nicht gerendert werden", systemImage: "exclamationmark.triangle")
                        .font(.headline)
                    Text(renderError)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ProgressView("Bauplan wird gerendert …")
                    .tint(.white)
                    .foregroundStyle(.white)
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .task(id: ProjectBuildPlanRasterizationKey(document: document, configuration: configuration)) {
            await rasterizePreview()
        }
    }

    @MainActor
    private func rasterizePreview() async {
        do {
            let image = try await Task.detached(priority: .userInitiated) {
                try BuildPlanRasterizer.makeImage(
                    document: document,
                    configuration: configuration
                )
            }.value

            rasterizedImage = image
            renderError = nil
        } catch {
            rasterizedImage = nil
            renderError = error.localizedDescription
        }
    }
}

private struct ProjectBuildPlanRasterizationKey: Hashable {
    let document: BuildPlanRenderDocument
    let configuration: BuildPlanRasterizationConfiguration
}

private struct ProjectDetailStats: View {
    let content: ProjectDetailContent

    var body: some View {
        ViewThatFits {
            HStack(spacing: 12) {
                statCards
            }

            VStack(spacing: 12) {
                statCards
            }
        }
    }

    @ViewBuilder
    private var statCards: some View {
        statCard(
            title: "Gesamtteile",
            value: "\(content.totalPieces)",
            detail: "Alle Noppen im finalen Raster",
            tint: Color(red: 0.97, green: 0.63, blue: 0.23)
        )
        statCard(
            title: "Farben",
            value: "\(content.distinctColorCount)",
            detail: "Verwendete Legendenfarben",
            tint: Color(red: 0.19, green: 0.65, blue: 0.56)
        )
        statCard(
            title: "Bauteil",
            value: content.partName,
            detail: "Einheitliche Teilebasis",
            tint: Color(red: 0.21, green: 0.45, blue: 0.85)
        )
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

private struct ProjectDetailPartsList: View {
    let content: ProjectDetailContent

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
                    ProjectDetailPartsListRow(row: row)
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

private struct ProjectDetailPartsListRow: View {
    let row: ProjectDetailPartRow

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

private struct ProjectDetailInlineStateCard: View {
    let title: String
    let message: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 52, height: 52)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.systemBackground))
        )
    }
}

private struct ProjectDetailEmptyState: View {
    let configuration: ProjectDetailEmptyConfiguration

    var body: some View {
        stateCard(
            title: configuration.title,
            message: configuration.message,
            systemImage: configuration.systemImage,
            tint: Color(red: 0.93, green: 0.58, blue: 0.21)
        )
    }

    private func stateCard(title: String, message: String, systemImage: String, tint: Color) -> some View {
        ProjectDetailStateCard(title: title, message: message, systemImage: systemImage, tint: tint)
    }
}

private struct ProjectDetailErrorState: View {
    let configuration: ProjectDetailErrorConfiguration

    var body: some View {
        ProjectDetailStateCard(
            title: configuration.title,
            message: configuration.message,
            systemImage: configuration.systemImage,
            tint: Color(red: 0.79, green: 0.24, blue: 0.24)
        )
    }
}

private struct ProjectDetailStateCard: View {
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

private struct ProjectDetailBackground: View {
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

private extension BuildPlanRasterizationConfiguration {
    static let projectDetailWide = BuildPlanRasterizationConfiguration(
        legendLayout: .leading,
        purpose: .display
    )

    static let projectDetailCompact = BuildPlanRasterizationConfiguration(
        legendLayout: .top,
        purpose: .display
    )
}

private extension DateFormatter {
    static let projectDetailTimestamp: DateFormatter = {
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

#Preview("Bauplan") {
    NavigationStack {
        ProjectDetailView(state: .loaded(ProjectDetailContent(project: PreviewProjects.generated)))
    }
}

#Preview("Leer") {
    NavigationStack {
        ProjectDetailView(state: .empty(
            ProjectDetailEmptyConfiguration(
                title: "Noch kein generiertes Projekt",
                message: "Der Bauplan erscheint hier, sobald das Projekt vollständig generiert wurde.",
                systemImage: "shippingbox"
            )
        ))
    }
}

#Preview("Fehler") {
    NavigationStack {
        ProjectDetailView(state: .error(
            ProjectDetailErrorConfiguration(
                title: "Projekt konnte nicht geladen werden",
                message: "Die Projektartefakte sind unvollständig oder beschädigt. Lade das Projekt erneut oder generiere es neu.",
                systemImage: "exclamationmark.triangle"
            )
        ))
    }
}
