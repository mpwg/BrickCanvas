import Foundation

enum MosaicDitheringMethod: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
    case threshold
    case floydSteinberg
    case atkinson
    case jarvisJudiceNinke
    case bayer

    static let storageKey = "mosaicDitheringMethod"

    var id: Self { self }

    var title: String {
        switch self {
        case .threshold:
            "Threshold"
        case .floydSteinberg:
            "Floyd-Steinberg"
        case .atkinson:
            "Atkinson"
        case .jarvisJudiceNinke:
            "Jarvis-Judice-Ninke"
        case .bayer:
            "Bayer"
        }
    }

    var shortDescription: String {
        switch self {
        case .threshold:
            "Ohne Dithering, nur direkte Zuordnung zur nächsten Palettenfarbe."
        case .floydSteinberg:
            "Klassische Error-Diffusion mit markanter Detailzeichnung."
        case .atkinson:
            "Leichter, kontrastreicher Stil mit reduzierter Fehlerverteilung."
        case .jarvisJudiceNinke:
            "Weichere Error-Diffusion mit guter Stillbildqualität."
        case .bayer:
            "Geordnetes Dithering mit klarer, regelmäßiger Struktur."
        }
    }

    var detailDescription: String {
        switch self {
        case .threshold:
            "Am schnellsten und vollständig deterministisch, aber mit den härtesten Tonwertsprüngen."
        case .floydSteinberg:
            "Bewährter Standard für natürliche Details und die beste Baseline für klassische Mosaik-Umsetzungen."
        case .atkinson:
            "Verteilt den Fehler nur teilweise und erzeugt dadurch ein ruhigeres, grafischeres Ergebnis."
        case .jarvisJudiceNinke:
            "Verteilt den Fehler über ein größeres Umfeld und ist hier der Standard für neue Projekte."
        case .bayer:
            "Sinnvoll, wenn ein bewusst technischer, regelmäßiger Raster-Look gewünscht ist."
        }
    }
}
