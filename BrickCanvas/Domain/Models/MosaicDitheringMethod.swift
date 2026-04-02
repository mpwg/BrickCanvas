import Foundation

enum MosaicDitheringMethod: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
    case floydSteinberg
    case ostromoukhov

    static let storageKey = "mosaicDitheringMethod"

    var id: Self { self }

    var title: String {
        switch self {
        case .floydSteinberg:
            "Floyd-Steinberg"
        case .ostromoukhov:
            "Ostromoukhov"
        }
    }

    var shortDescription: String {
        switch self {
        case .floydSteinberg:
            "Klassische Error-Diffusion mit robuster, schneller Baseline."
        case .ostromoukhov:
            "Moderne variable Koeffizienten für sichtbar feinere Tonwertverläufe."
        }
    }

    var detailDescription: String {
        switch self {
        case .floydSteinberg:
            "Bewährter Standard mit gutem Verhältnis aus Qualität, Geschwindigkeit und Vorhersagbarkeit."
        case .ostromoukhov:
            "Qualitätsorientierte Error-Diffusion nach Ostromoukhov mit helligkeitsabhängigen Gewichten für gleichmäßigere Strukturen."
        }
    }
}
