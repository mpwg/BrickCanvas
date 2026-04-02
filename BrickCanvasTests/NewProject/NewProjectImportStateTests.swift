import Foundation
import Testing
@testable import BrickCanvas

struct NewProjectImportStateTests {
    @Test
    func invalidInputMapsToActionablePresentation() {
        let presentation = ImportErrorPresentation.from(
            ServiceError.invalidInput("Die Datei enthält keine lesbaren Bilddaten.")
        )

        #expect(presentation.title == "Ungültige Bilddaten")
        #expect(presentation.message == "Die Datei enthält keine lesbaren Bilddaten.")
        #expect(presentation.recoverySuggestion.contains("anderes Foto"))
    }

    @Test
    func unsupportedFormatMapsToFormatGuidance() {
        let presentation = ImportErrorPresentation.from(
            ServiceError.unsupportedOperation("Das gewählte Bildformat wird nicht unterstützt.")
        )

        #expect(presentation.title == "Format nicht unterstützt")
        #expect(presentation.recoverySuggestion.contains("JPEG"))
    }

    @Test
    func permissionLikeErrorsMapToAccessDeniedPresentation() {
        let error = NSError(
            domain: "PHPhotosErrorDomain",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Photo library access not authorized."]
        )
        let presentation = ImportErrorPresentation.from(error)

        #expect(presentation.title == "Fotozugriff verweigert")
        #expect(presentation.recoverySuggestion.contains("Zugriff"))
    }

    @Test
    func importStateRunningFlagTracksOnlyActiveImport() {
        #expect(NewProjectImportState.idle.isRunning == false)
        #expect(NewProjectImportState.importing(.normalizingImage).isRunning)
        #expect(NewProjectImportState.failed(.from(ServiceError.processingFailed("Fehler"))).isRunning == false)
    }
}
