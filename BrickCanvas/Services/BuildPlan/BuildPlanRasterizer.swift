import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum BuildPlanLegendLayout: Hashable, Sendable {
    case top
    case leading
}

enum BuildPlanRasterizationPurpose: Hashable, Sendable {
    case display
    case export
}

struct BuildPlanRasterizationConfiguration: Hashable, Sendable {
    let legendLayout: BuildPlanLegendLayout
    let purpose: BuildPlanRasterizationPurpose

    static func display(for availableWidth: CGFloat) -> BuildPlanRasterizationConfiguration {
        BuildPlanRasterizationConfiguration(
            legendLayout: availableWidth < 760 ? .top : .leading,
            purpose: .display
        )
    }

    static let export = BuildPlanRasterizationConfiguration(
        legendLayout: .leading,
        purpose: .export
    )
}

struct BuildPlanRenderLegendItem: Identifiable, Hashable, Sendable {
    let number: Int
    let colorID: String
    let colorName: String
    let colorSubtitle: String
    let swatchColor: RGBColor

    var id: Int {
        number
    }
}

struct BuildPlanRenderDocument: Hashable, Sendable {
    let projectName: String
    let partName: String
    let gridDescription: String
    let buildPlan: BuildPlan
    let legendItems: [BuildPlanRenderLegendItem]

    init?(project: BrickCanvasProject) {
        guard let artifacts = project.generatedArtifacts,
              let buildPlan = artifacts.buildPlan else {
            return nil
        }

        let paletteByID = Dictionary(uniqueKeysWithValues: artifacts.palette.map { ($0.id, $0) })

        self.projectName = project.name
        self.partName = project.configuration.part.displayName
        self.gridDescription = "\(project.configuration.mosaicSize.width) × \(project.configuration.mosaicSize.height) Noppen"
        self.buildPlan = buildPlan
        self.legendItems = buildPlan.legend.map { entry in
            let paletteColor = paletteByID[entry.colorID]

            return BuildPlanRenderLegendItem(
                number: entry.number,
                colorID: entry.colorID,
                colorName: paletteColor?.name ?? entry.colorID.humanizedColorID,
                colorSubtitle: paletteColor?.rgb.hexString ?? entry.colorID.uppercased(),
                swatchColor: paletteColor?.rgb ?? RGBColor(red: 142, green: 142, blue: 147)
            )
        }
    }
}

enum BuildPlanRasterizer {
    static func canvasSize(
        for document: BuildPlanRenderDocument,
        configuration: BuildPlanRasterizationConfiguration
    ) -> CGSize {
        let metrics = BuildPlanRasterizationMetrics(
            configuration: configuration,
            gridSize: document.buildPlan.size,
            legendItemCount: document.legendItems.count
        )

        return BuildPlanCanvasLayout(metrics: metrics).canvasSize
    }

    static func makeImage(
        document: BuildPlanRenderDocument,
        configuration: BuildPlanRasterizationConfiguration
    ) throws -> CGImage {
        let metrics = BuildPlanRasterizationMetrics(
            configuration: configuration,
            gridSize: document.buildPlan.size,
            legendItemCount: document.legendItems.count
        )
        let layout = BuildPlanCanvasLayout(metrics: metrics)
        let canvasSize = layout.canvasSize
        let width = Int(canvasSize.width.rounded(.up))
        let height = Int(canvasSize.height.rounded(.up))

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: nil,
                  width: width,
                  height: height,
                  bitsPerComponent: 8,
                  bytesPerRow: 0,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            throw ServiceError.processingFailed("Der Bauplan konnte nicht gerendert werden.")
        }

        drawBackground(in: context, canvasSize: canvasSize, metrics: metrics)
        drawHeader(
            in: context,
            canvasSize: canvasSize,
            rect: layout.headerRect,
            document: document,
            metrics: metrics
        )
        drawLegend(
            in: context,
            canvasSize: canvasSize,
            rect: layout.legendRect,
            items: document.legendItems,
            metrics: metrics
        )
        drawGridPanel(
            in: context,
            canvasSize: canvasSize,
            rect: layout.gridPanelRect,
            document: document,
            metrics: metrics
        )

        guard let image = context.makeImage() else {
            throw ServiceError.processingFailed("Das Bauplanbild konnte nicht abgeschlossen werden.")
        }

        return image
    }

    static func makePNGData(
        document: BuildPlanRenderDocument,
        configuration: BuildPlanRasterizationConfiguration
    ) throws -> Data {
        let image = try makeImage(document: document, configuration: configuration)
        let mutableData = NSMutableData()

        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw ServiceError.processingFailed("Die PNG-Ausgabe konnte nicht vorbereitet werden.")
        }

        CGImageDestinationAddImage(destination, image, nil)

        guard CGImageDestinationFinalize(destination) else {
            throw ServiceError.processingFailed("Der Bauplan konnte nicht als PNG kodiert werden.")
        }

        return mutableData as Data
    }

    private static func drawBackground(
        in context: CGContext,
        canvasSize: CGSize,
        metrics: BuildPlanRasterizationMetrics
    ) {
        fill(
            CGRect(origin: .zero, size: canvasSize),
            color: metrics.pageBackgroundColor,
            in: context,
            canvasSize: canvasSize
        )
    }

    private static func drawHeader(
        in context: CGContext,
        canvasSize: CGSize,
        rect: CGRect,
        document: BuildPlanRenderDocument,
        metrics: BuildPlanRasterizationMetrics
    ) {
        fillRoundedRect(rect, cornerRadius: metrics.cardCornerRadius, color: metrics.headerBackgroundColor, in: context, canvasSize: canvasSize)
        strokeRoundedRect(rect, cornerRadius: metrics.cardCornerRadius, color: metrics.headerBorderColor, lineWidth: 1, in: context, canvasSize: canvasSize)

        let eyebrowPoint = CGPoint(x: rect.minX + metrics.cardPadding, y: rect.minY + metrics.cardPadding)
        drawText(
            "BAUPLAN",
            at: eyebrowPoint,
            style: TextStyle(fontSize: metrics.eyebrowFontSize, color: metrics.mutedTextColor, fontName: metrics.mediumFontName),
            in: context,
            canvasSize: canvasSize
        )
        drawText(
            document.projectName,
            at: CGPoint(x: eyebrowPoint.x, y: eyebrowPoint.y + metrics.eyebrowFontSize + 12),
            style: TextStyle(fontSize: metrics.titleFontSize, color: metrics.primaryTextColor, fontName: metrics.boldFontName),
            in: context,
            canvasSize: canvasSize
        )
        drawText(
            "Nummerierter LEGO-Art-Bauplan mit Koordinaten und Farblegende.",
            at: CGPoint(x: eyebrowPoint.x, y: eyebrowPoint.y + metrics.eyebrowFontSize + metrics.titleFontSize + 24),
            style: TextStyle(fontSize: metrics.bodyFontSize, color: metrics.secondaryTextColor, fontName: metrics.regularFontName),
            in: context,
            canvasSize: canvasSize
        )

        let metaTexts = [
            document.partName,
            document.gridDescription,
            "\(document.legendItems.count) Farben"
        ]
        let pillOriginY = rect.maxY - metrics.cardPadding - metrics.metaPillHeight
        var currentX = rect.minX + metrics.cardPadding

        for text in metaTexts {
            let pillWidth = max(measureTextWidth(text, style: TextStyle(fontSize: metrics.metaFontSize, color: metrics.primaryTextColor, fontName: metrics.mediumFontName)) + 30, 110)
            let pillRect = CGRect(x: currentX, y: pillOriginY, width: pillWidth, height: metrics.metaPillHeight)
            fillRoundedRect(pillRect, cornerRadius: metrics.metaPillHeight / 2, color: metrics.metaPillBackgroundColor, in: context, canvasSize: canvasSize)
            drawCenteredText(
                text,
                in: pillRect,
                style: TextStyle(fontSize: metrics.metaFontSize, color: metrics.primaryTextColor, fontName: metrics.mediumFontName),
                in: context,
                canvasSize: canvasSize
            )
            currentX += pillWidth + 10
        }
    }

    private static func drawLegend(
        in context: CGContext,
        canvasSize: CGSize,
        rect: CGRect,
        items: [BuildPlanRenderLegendItem],
        metrics: BuildPlanRasterizationMetrics
    ) {
        fillRoundedRect(rect, cornerRadius: metrics.cardCornerRadius, color: metrics.legendBackgroundColor, in: context, canvasSize: canvasSize)
        strokeRoundedRect(rect, cornerRadius: metrics.cardCornerRadius, color: metrics.legendBorderColor, lineWidth: 1, in: context, canvasSize: canvasSize)

        drawText(
            "Farblegende",
            at: CGPoint(x: rect.minX + metrics.cardPadding, y: rect.minY + metrics.cardPadding),
            style: TextStyle(fontSize: metrics.sectionTitleFontSize, color: metrics.primaryTextColor, fontName: metrics.boldFontName),
            in: context,
            canvasSize: canvasSize
        )
        drawText(
            "Jede Zahl entspricht einer Farbe im Raster.",
            at: CGPoint(x: rect.minX + metrics.cardPadding, y: rect.minY + metrics.cardPadding + metrics.sectionTitleFontSize + 10),
            style: TextStyle(fontSize: metrics.bodyFontSize, color: metrics.secondaryTextColor, fontName: metrics.regularFontName),
            in: context,
            canvasSize: canvasSize
        )

        let itemRects = BuildPlanLegendLayoutCalculator.itemRects(
            in: rect,
            itemCount: items.count,
            metrics: metrics
        )

        for (item, itemRect) in zip(items, itemRects) {
            fillRoundedRect(itemRect, cornerRadius: metrics.itemCornerRadius, color: metrics.legendItemBackgroundColor, in: context, canvasSize: canvasSize)
            strokeRoundedRect(itemRect, cornerRadius: metrics.itemCornerRadius, color: metrics.legendItemBorderColor, lineWidth: 1, in: context, canvasSize: canvasSize)

            let badgeRect = CGRect(
                x: itemRect.minX + 12,
                y: itemRect.midY - 18,
                width: 36,
                height: 36
            )
            fillEllipse(badgeRect, color: item.swatchColor.cgColor, in: context, canvasSize: canvasSize)
            drawCenteredText(
                "\(item.number)",
                in: badgeRect,
                style: TextStyle(
                    fontSize: metrics.legendNumberFontSize,
                    color: item.swatchColor.contrastingTextColor,
                    fontName: metrics.boldFontName
                ),
                in: context,
                canvasSize: canvasSize
            )

            let textOriginX = badgeRect.maxX + 12
            drawText(
                item.colorName,
                at: CGPoint(x: textOriginX, y: itemRect.minY + 11),
                style: TextStyle(fontSize: metrics.bodyFontSize, color: metrics.primaryTextColor, fontName: metrics.mediumFontName),
                in: context,
                canvasSize: canvasSize
            )
            drawText(
                item.colorSubtitle,
                at: CGPoint(x: textOriginX, y: itemRect.minY + 11 + metrics.bodyFontSize + 6),
                style: TextStyle(fontSize: metrics.captionFontSize, color: metrics.secondaryTextColor, fontName: metrics.regularFontName),
                in: context,
                canvasSize: canvasSize
            )
        }
    }

    private static func drawGridPanel(
        in context: CGContext,
        canvasSize: CGSize,
        rect: CGRect,
        document: BuildPlanRenderDocument,
        metrics: BuildPlanRasterizationMetrics
    ) {
        fillRoundedRect(rect, cornerRadius: metrics.cardCornerRadius, color: metrics.panelBackgroundColor, in: context, canvasSize: canvasSize)
        strokeRoundedRect(rect, cornerRadius: metrics.cardCornerRadius, color: metrics.panelBorderColor, lineWidth: 1, in: context, canvasSize: canvasSize)

        drawText(
            "Bauraster",
            at: CGPoint(x: rect.minX + metrics.cardPadding, y: rect.minY + metrics.cardPadding),
            style: TextStyle(fontSize: metrics.sectionTitleFontSize, color: metrics.primaryTextColor, fontName: metrics.boldFontName),
            in: context,
            canvasSize: canvasSize
        )
        drawText(
            "Koordinaten oben und links, Zahlen direkt auf jeder Noppe.",
            at: CGPoint(x: rect.minX + metrics.cardPadding, y: rect.minY + metrics.cardPadding + metrics.sectionTitleFontSize + 10),
            style: TextStyle(fontSize: metrics.bodyFontSize, color: metrics.secondaryTextColor, fontName: metrics.regularFontName),
            in: context,
            canvasSize: canvasSize
        )

        let gridOrigin = CGPoint(
            x: rect.minX + metrics.cardPadding + metrics.axisLabelSpan,
            y: rect.minY + metrics.cardPadding + metrics.gridTopOffset
        )
        let gridSize = CGSize(
            width: CGFloat(document.buildPlan.size.width) * metrics.cellStep,
            height: CGFloat(document.buildPlan.size.height) * metrics.cellStep
        )
        let plateRect = CGRect(
            x: gridOrigin.x - metrics.platePadding,
            y: gridOrigin.y - metrics.platePadding,
            width: gridSize.width + (metrics.platePadding * 2),
            height: gridSize.height + (metrics.platePadding * 2)
        )

        fillRoundedRect(plateRect, cornerRadius: metrics.plateCornerRadius, color: metrics.plateColor, in: context, canvasSize: canvasSize)
        strokeRoundedRect(plateRect, cornerRadius: metrics.plateCornerRadius, color: metrics.plateBorderColor, lineWidth: 2, in: context, canvasSize: canvasSize)

        for column in 0..<document.buildPlan.size.width {
            let labelRect = CGRect(
                x: gridOrigin.x + CGFloat(column) * metrics.cellStep,
                y: gridOrigin.y - metrics.axisLabelSpan,
                width: metrics.cellStep,
                height: metrics.axisLabelSpan - 10
            )
            drawCenteredText(
                "\(column + 1)",
                in: labelRect,
                style: TextStyle(fontSize: metrics.axisFontSize, color: metrics.secondaryTextColor, fontName: metrics.mediumFontName),
                in: context,
                canvasSize: canvasSize
            )
        }

        for rowIndex in 0..<document.buildPlan.size.height {
            let labelRect = CGRect(
                x: gridOrigin.x - metrics.axisLabelSpan,
                y: gridOrigin.y + CGFloat(rowIndex) * metrics.cellStep,
                width: metrics.axisLabelSpan - 10,
                height: metrics.cellStep
            )
            drawCenteredText(
                "\(rowIndex + 1)",
                in: labelRect,
                style: TextStyle(fontSize: metrics.axisFontSize, color: metrics.secondaryTextColor, fontName: metrics.mediumFontName),
                in: context,
                canvasSize: canvasSize
            )
        }

        let legendByNumber = Dictionary(uniqueKeysWithValues: document.legendItems.map { ($0.number, $0) })

        for row in document.buildPlan.rows {
            for stud in row.studs {
                let cellRect = CGRect(
                    x: gridOrigin.x + CGFloat(stud.columnIndex) * metrics.cellStep,
                    y: gridOrigin.y + CGFloat(row.rowIndex) * metrics.cellStep,
                    width: metrics.cellStep,
                    height: metrics.cellStep
                )
                let studRect = cellRect.insetBy(dx: metrics.studInset, dy: metrics.studInset)
                let swatchColor = legendByNumber[stud.legendNumber]?.swatchColor ?? RGBColor(red: 142, green: 142, blue: 147)

                fillEllipse(studRect, color: swatchColor.cgColor, in: context, canvasSize: canvasSize)
                strokeEllipse(studRect, color: metrics.studStrokeColor, lineWidth: 2, in: context, canvasSize: canvasSize)
                drawCenteredText(
                    "\(stud.legendNumber)",
                    in: studRect,
                    style: TextStyle(
                        fontSize: metrics.studNumberFontSize,
                        color: swatchColor.contrastingTextColor,
                        fontName: metrics.boldFontName
                    ),
                    in: context,
                    canvasSize: canvasSize
                )
            }
        }
    }
}

private struct BuildPlanCanvasLayout {
    let canvasSize: CGSize
    let headerRect: CGRect
    let legendRect: CGRect
    let gridPanelRect: CGRect

    init(metrics: BuildPlanRasterizationMetrics) {
        let gridPanelSize = BuildPlanCanvasLayout.gridPanelSize(metrics: metrics)
        let legendSize = BuildPlanCanvasLayout.legendSize(metrics: metrics)

        switch metrics.configuration.legendLayout {
        case .leading:
            let contentWidth = legendSize.width + metrics.sectionSpacing + gridPanelSize.width
            let contentHeight = max(legendSize.height, gridPanelSize.height)
            let width = contentWidth + (metrics.canvasPadding * 2)
            let height = metrics.canvasPadding + metrics.headerHeight + metrics.sectionSpacing + contentHeight + metrics.canvasPadding

            self.canvasSize = CGSize(width: width, height: height)
            self.headerRect = CGRect(
                x: metrics.canvasPadding,
                y: metrics.canvasPadding,
                width: contentWidth,
                height: metrics.headerHeight
            )
            self.legendRect = CGRect(
                x: metrics.canvasPadding,
                y: headerRect.maxY + metrics.sectionSpacing,
                width: legendSize.width,
                height: legendSize.height
            )
            self.gridPanelRect = CGRect(
                x: legendRect.maxX + metrics.sectionSpacing,
                y: headerRect.maxY + metrics.sectionSpacing,
                width: gridPanelSize.width,
                height: gridPanelSize.height
            )
        case .top:
            let contentWidth = max(legendSize.width, gridPanelSize.width)
            let width = contentWidth + (metrics.canvasPadding * 2)
            let height = metrics.canvasPadding + metrics.headerHeight + metrics.sectionSpacing + legendSize.height + metrics.sectionSpacing + gridPanelSize.height + metrics.canvasPadding

            self.canvasSize = CGSize(width: width, height: height)
            self.headerRect = CGRect(
                x: metrics.canvasPadding,
                y: metrics.canvasPadding,
                width: contentWidth,
                height: metrics.headerHeight
            )
            self.legendRect = CGRect(
                x: metrics.canvasPadding,
                y: headerRect.maxY + metrics.sectionSpacing,
                width: contentWidth,
                height: legendSize.height
            )
            self.gridPanelRect = CGRect(
                x: metrics.canvasPadding,
                y: legendRect.maxY + metrics.sectionSpacing,
                width: gridPanelSize.width,
                height: gridPanelSize.height
            )
        }
    }

    private static func gridPanelSize(metrics: BuildPlanRasterizationMetrics) -> CGSize {
        let gridWidth = CGFloat(metrics.gridSize.width) * metrics.cellStep
        let gridHeight = CGFloat(metrics.gridSize.height) * metrics.cellStep

        return CGSize(
            width: (metrics.cardPadding * 2) + metrics.axisLabelSpan + gridWidth,
            height: metrics.cardPadding + metrics.gridTopOffset + gridHeight + metrics.cardPadding
        )
    }

    private static func legendSize(metrics: BuildPlanRasterizationMetrics) -> CGSize {
        let itemRects = BuildPlanLegendLayoutCalculator.itemRects(
            in: CGRect(origin: .zero, size: CGSize(width: metrics.legendWidth, height: 10_000)),
            itemCount: metrics.legendItemCount,
            metrics: metrics
        )
        let contentBottom = itemRects.last?.maxY ?? (metrics.cardPadding + metrics.sectionTitleFontSize + 36)

        return CGSize(
            width: metrics.legendWidth,
            height: contentBottom + metrics.cardPadding
        )
    }
}

private struct BuildPlanLegendLayoutCalculator {
    static func itemRects(
        in rect: CGRect,
        itemCount: Int,
        metrics: BuildPlanRasterizationMetrics
    ) -> [CGRect] {
        let availableWidth = rect.width - (metrics.cardPadding * 2)
        let columnCount: Int

        switch metrics.configuration.legendLayout {
        case .leading:
            columnCount = 1
        case .top:
            columnCount = availableWidth >= ((metrics.legendItemWidth * 2) + metrics.legendItemSpacing) ? 2 : 1
        }

        let itemWidth = columnCount == 1
            ? availableWidth
            : (availableWidth - (CGFloat(columnCount - 1) * metrics.legendItemSpacing)) / CGFloat(columnCount)
        let startY = rect.minY + metrics.cardPadding + metrics.sectionTitleFontSize + 36

        return (0..<itemCount).map { index in
            let row = index / columnCount
            let column = index % columnCount

            return CGRect(
                x: rect.minX + metrics.cardPadding + CGFloat(column) * (itemWidth + metrics.legendItemSpacing),
                y: startY + CGFloat(row) * (metrics.legendItemHeight + metrics.legendItemSpacing),
                width: itemWidth,
                height: metrics.legendItemHeight
            )
        }
    }
}

private struct BuildPlanRasterizationMetrics {
    let configuration: BuildPlanRasterizationConfiguration
    let gridSize: MosaicGridSize
    let legendItemCount: Int

    let canvasPadding: CGFloat
    let sectionSpacing: CGFloat
    let cardPadding: CGFloat
    let headerHeight: CGFloat
    let cardCornerRadius: CGFloat
    let itemCornerRadius: CGFloat
    let plateCornerRadius: CGFloat
    let legendWidth: CGFloat
    let legendItemWidth: CGFloat
    let legendItemHeight: CGFloat
    let legendItemSpacing: CGFloat
    let axisLabelSpan: CGFloat
    let cellStep: CGFloat
    let studInset: CGFloat
    let platePadding: CGFloat
    let gridTopOffset: CGFloat
    let titleFontSize: CGFloat
    let sectionTitleFontSize: CGFloat
    let bodyFontSize: CGFloat
    let captionFontSize: CGFloat
    let axisFontSize: CGFloat
    let eyebrowFontSize: CGFloat
    let studNumberFontSize: CGFloat
    let legendNumberFontSize: CGFloat
    let metaFontSize: CGFloat
    let metaPillHeight: CGFloat
    let primaryTextColor: CGColor
    let secondaryTextColor: CGColor
    let mutedTextColor: CGColor
    let pageBackgroundColor: CGColor
    let headerBackgroundColor: CGColor
    let headerBorderColor: CGColor
    let metaPillBackgroundColor: CGColor
    let legendBackgroundColor: CGColor
    let legendBorderColor: CGColor
    let legendItemBackgroundColor: CGColor
    let legendItemBorderColor: CGColor
    let panelBackgroundColor: CGColor
    let panelBorderColor: CGColor
    let plateColor: CGColor
    let plateBorderColor: CGColor
    let studStrokeColor: CGColor
    let regularFontName: String
    let mediumFontName: String
    let boldFontName: String

    init(
        configuration: BuildPlanRasterizationConfiguration,
        gridSize: MosaicGridSize,
        legendItemCount: Int
    ) {
        self.configuration = configuration
        self.gridSize = gridSize
        self.legendItemCount = legendItemCount

        switch configuration.purpose {
        case .display:
            canvasPadding = 24
            sectionSpacing = 18
            cardPadding = 20
            headerHeight = 156
            cardCornerRadius = 28
            itemCornerRadius = 18
            plateCornerRadius = 18
            legendWidth = configuration.legendLayout == .leading ? 260 : 520
            legendItemWidth = configuration.legendLayout == .leading ? 220 : 240
            legendItemHeight = 62
            legendItemSpacing = 10
            axisLabelSpan = 26
            cellStep = BuildPlanRasterizationMetrics.cellStep(for: gridSize, purpose: .display)
            studInset = 3
            platePadding = 14
            gridTopOffset = 60
            titleFontSize = 28
            sectionTitleFontSize = 22
            bodyFontSize = 15
            captionFontSize = 12
            axisFontSize = 12
            eyebrowFontSize = 12
            studNumberFontSize = max(cellStep * 0.36, 11)
            legendNumberFontSize = 16
            metaFontSize = 13
            metaPillHeight = 30
        case .export:
            canvasPadding = 40
            sectionSpacing = 28
            cardPadding = 28
            headerHeight = 206
            cardCornerRadius = 34
            itemCornerRadius = 22
            plateCornerRadius = 24
            legendWidth = 320
            legendItemWidth = 260
            legendItemHeight = 78
            legendItemSpacing = 14
            axisLabelSpan = 34
            cellStep = BuildPlanRasterizationMetrics.cellStep(for: gridSize, purpose: .export)
            studInset = 4
            platePadding = 20
            gridTopOffset = 82
            titleFontSize = 40
            sectionTitleFontSize = 28
            bodyFontSize = 18
            captionFontSize = 14
            axisFontSize = 16
            eyebrowFontSize = 14
            studNumberFontSize = max(cellStep * 0.4, 14)
            legendNumberFontSize = 20
            metaFontSize = 16
            metaPillHeight = 38
        }

        primaryTextColor = RGBColor(red: 245, green: 247, blue: 250).cgColor
        secondaryTextColor = RGBColor(red: 188, green: 197, blue: 210).cgColor
        mutedTextColor = RGBColor(red: 143, green: 154, blue: 168).cgColor
        pageBackgroundColor = RGBColor(red: 13, green: 19, blue: 28).cgColor
        headerBackgroundColor = RGBColor(red: 23, green: 34, blue: 48).cgColor
        headerBorderColor = RGBColor(red: 44, green: 63, blue: 86).cgColor
        metaPillBackgroundColor = RGBColor(red: 33, green: 48, blue: 66).cgColor
        legendBackgroundColor = RGBColor(red: 20, green: 29, blue: 41).cgColor
        legendBorderColor = RGBColor(red: 42, green: 60, blue: 80).cgColor
        legendItemBackgroundColor = RGBColor(red: 28, green: 39, blue: 53).cgColor
        legendItemBorderColor = RGBColor(red: 48, green: 67, blue: 88).cgColor
        panelBackgroundColor = RGBColor(red: 20, green: 29, blue: 41).cgColor
        panelBorderColor = RGBColor(red: 42, green: 60, blue: 80).cgColor
        plateColor = RGBColor(red: 50, green: 54, blue: 58).cgColor
        plateBorderColor = RGBColor(red: 120, green: 126, blue: 133).cgColor
        studStrokeColor = RGBColor(red: 255, green: 255, blue: 255).cgColor.copy(alpha: 0.14) ?? RGBColor(red: 255, green: 255, blue: 255).cgColor
        regularFontName = "HelveticaNeue"
        mediumFontName = "HelveticaNeue-Medium"
        boldFontName = "HelveticaNeue-Bold"
    }

    private static func cellStep(
        for gridSize: MosaicGridSize,
        purpose: BuildPlanRasterizationPurpose
    ) -> CGFloat {
        let longestEdge = max(gridSize.width, gridSize.height)

        return switch purpose {
        case .display:
            switch longestEdge {
            case ...24: 34
            case ...48: 24
            default: 18
            }
        case .export:
            switch longestEdge {
            case ...24: 46
            case ...48: 34
            default: 26
            }
        }
    }
}

private struct TextStyle {
    let fontSize: CGFloat
    let color: CGColor
    let fontName: String
}

private func fill(_ rect: CGRect, color: CGColor, in context: CGContext, canvasSize: CGSize) {
    context.setFillColor(color)
    context.fill(convert(rect, canvasHeight: canvasSize.height))
}

private func fillRoundedRect(
    _ rect: CGRect,
    cornerRadius: CGFloat,
    color: CGColor,
    in context: CGContext,
    canvasSize: CGSize
) {
    context.setFillColor(color)
    let path = CGPath(roundedRect: convert(rect, canvasHeight: canvasSize.height), cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    context.addPath(path)
    context.fillPath()
}

private func strokeRoundedRect(
    _ rect: CGRect,
    cornerRadius: CGFloat,
    color: CGColor,
    lineWidth: CGFloat,
    in context: CGContext,
    canvasSize: CGSize
) {
    context.setStrokeColor(color)
    context.setLineWidth(lineWidth)
    let path = CGPath(roundedRect: convert(rect, canvasHeight: canvasSize.height), cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    context.addPath(path)
    context.strokePath()
}

private func fillEllipse(_ rect: CGRect, color: CGColor, in context: CGContext, canvasSize: CGSize) {
    context.setFillColor(color)
    context.fillEllipse(in: convert(rect, canvasHeight: canvasSize.height))
}

private func strokeEllipse(_ rect: CGRect, color: CGColor, lineWidth: CGFloat, in context: CGContext, canvasSize: CGSize) {
    context.setStrokeColor(color)
    context.setLineWidth(lineWidth)
    context.strokeEllipse(in: convert(rect, canvasHeight: canvasSize.height))
}

private func drawText(
    _ text: String,
    at point: CGPoint,
    style: TextStyle,
    in context: CGContext,
    canvasSize: CGSize
) {
    guard text.isEmpty == false else {
        return
    }

    let attributedText = makeAttributedText(text, style: style)
    let line = CTLineCreateWithAttributedString(attributedText)
    var ascent: CGFloat = 0
    var descent: CGFloat = 0
    var leading: CGFloat = 0
    CTLineGetTypographicBounds(line, &ascent, &descent, &leading)

    context.saveGState()
    context.textMatrix = .identity
    context.textPosition = CGPoint(
        x: point.x,
        y: canvasSize.height - point.y - ascent
    )
    CTLineDraw(line, context)
    context.restoreGState()
}

private func drawCenteredText(
    _ text: String,
    in rect: CGRect,
    style: TextStyle,
    in context: CGContext,
    canvasSize: CGSize
) {
    let attributedText = makeAttributedText(text, style: style)
    let line = CTLineCreateWithAttributedString(attributedText)
    var ascent: CGFloat = 0
    var descent: CGFloat = 0
    var leading: CGFloat = 0
    let width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))
    let height = ascent + descent
    let origin = CGPoint(
        x: rect.midX - (width / 2),
        y: rect.midY - (height / 2)
    )

    drawText(text, at: origin, style: style, in: context, canvasSize: canvasSize)
}

private func measureTextWidth(_ text: String, style: TextStyle) -> CGFloat {
    let attributedText = makeAttributedText(text, style: style)
    let line = CTLineCreateWithAttributedString(attributedText)
    return CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
}

private func makeAttributedText(_ text: String, style: TextStyle) -> NSAttributedString {
    let font = CTFontCreateWithName(style.fontName as CFString, style.fontSize, nil)

    return NSAttributedString(
        string: text,
        attributes: [
            kCTFontAttributeName as NSAttributedString.Key: font,
            kCTForegroundColorAttributeName as NSAttributedString.Key: style.color
        ]
    )
}

private func convert(_ rect: CGRect, canvasHeight: CGFloat) -> CGRect {
    CGRect(
        x: rect.minX,
        y: canvasHeight - rect.maxY,
        width: rect.width,
        height: rect.height
    )
}

private extension RGBColor {
    var cgColor: CGColor {
        CGColor(
            red: CGFloat(red) / 255.0,
            green: CGFloat(green) / 255.0,
            blue: CGFloat(blue) / 255.0,
            alpha: 1
        )
    }

    var contrastingTextColor: CGColor {
        relativeLuminance > 0.58
            ? RGBColor(red: 12, green: 17, blue: 22).cgColor
            : RGBColor(red: 255, green: 255, blue: 255).cgColor
    }

    private var relativeLuminance: CGFloat {
        let red = CGFloat(self.red) / 255.0
        let green = CGFloat(self.green) / 255.0
        let blue = CGFloat(self.blue) / 255.0

        return (0.2126 * red) + (0.7152 * green) + (0.0722 * blue)
    }
}
