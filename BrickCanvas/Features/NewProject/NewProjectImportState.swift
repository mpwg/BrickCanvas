import Foundation

enum ImportProgressStep: String, Equatable, Sendable {
    case requestingImageData
    case normalizingImage
    case preparingEditor

    var title: String {
        switch self {
        case .requestingImageData:
            "Bild wird geladen"
        case .normalizingImage:
            "Bild wird normalisiert"
        case .preparingEditor:
            "Editor wird vorbereitet"
        }
    }

    var message: String {
        switch self {
        case .requestingImageData:
            "Die ausgewählten Bilddaten werden aus deiner Mediathek übernommen."
        case .normalizingImage:
            "Orientierung und Bildformat werden für einen stabilen Zuschnitt vorbereitet."
        case .preparingEditor:
            "Die Vorschau wird aufgebaut, damit du direkt mit Framing und Größe weiterarbeiten kannst."
        }
    }
}

struct ImportErrorPresentation: Equatable, Sendable {
    let title: String
    let message: String
    let recoverySuggestion: String

    static func from(_ error: Error) -> ImportErrorPresentation {
        if let serviceError = error as? ServiceError {
            switch serviceError {
            case let .invalidInput(message):
                return ImportErrorPresentation(
                    title: "Ungültige Bilddaten",
                    message: message,
                    recoverySuggestion: "Wähle ein anderes Foto oder versuche den Import erneut."
                )
            case let .unsupportedOperation(message):
                return ImportErrorPresentation(
                    title: "Format nicht unterstützt",
                    message: message,
                    recoverySuggestion: "Nutze ein Standardbildformat wie JPEG, PNG oder HEIC."
                )
            case let .processingFailed(message):
                return ImportErrorPresentation(
                    title: "Bild konnte nicht verarbeitet werden",
                    message: message,
                    recoverySuggestion: "Versuche es erneut oder wähle ein anderes Foto mit klar lesbaren Bilddaten."
                )
            case let .unavailable(message):
                return ImportErrorPresentation(
                    title: "Import derzeit nicht verfügbar",
                    message: message,
                    recoverySuggestion: "Prüfe den Fotozugriff und versuche den Schritt erneut."
                )
            }
        }

        let nsError = error as NSError
        let lowercasedDescription = nsError.localizedDescription.lowercased()
        if nsError.domain.contains("PHPhotosErrorDomain")
            || lowercasedDescription.contains("permission")
            || lowercasedDescription.contains("not authorized")
            || lowercasedDescription.contains("zugriff")
            || lowercasedDescription.contains("berecht") {
            return ImportErrorPresentation(
                title: "Fotozugriff verweigert",
                message: nsError.localizedDescription,
                recoverySuggestion: "Erlaube den Zugriff auf deine Fotos und starte den Import danach erneut."
            )
        }

        return ImportErrorPresentation(
            title: "Import fehlgeschlagen",
            message: nsError.localizedDescription,
            recoverySuggestion: "Versuche es erneut. Wenn der Fehler bestehen bleibt, wähle ein anderes Bild."
        )
    }
}

enum NewProjectImportState: Equatable, Sendable {
    case idle
    case importing(ImportProgressStep)
    case failed(ImportErrorPresentation)

    var isRunning: Bool {
        if case .importing = self {
            return true
        }

        return false
    }
}
