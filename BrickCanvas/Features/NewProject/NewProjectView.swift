import SwiftUI

struct NewProjectView: View {
    var body: some View {
        PlaceholderScreen(
            eyebrow: "Flow",
            title: "Neues Projekt",
            message: "Dieser Screen reserviert den Einstieg für Bildimport und die ersten Schritte des linearen MVP-Flows.",
            bullets: [
                "Import aus Fotobibliothek oder Kamera",
                "Übergang zu Zuschnitt und Framing",
                "Spätere Fehler- und Ladezustände für Import"
            ],
            accentColor: .blue
        )
        .navigationTitle("Neues Projekt")
    }
}

#Preview {
    NavigationStack {
        NewProjectView()
    }
}

