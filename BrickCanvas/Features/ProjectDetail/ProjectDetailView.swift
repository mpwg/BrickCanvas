import SwiftUI

struct ProjectDetailView: View {
    var body: some View {
        PlaceholderScreen(
            eyebrow: "Projekt",
            title: "Projekte",
            message: "Der Tab steht als Platzhalter für Projektliste, Ergebnisansicht und Wiederaufnahme gespeicherter Arbeiten.",
            bullets: [
                "Liste gespeicherter Projekte",
                "Spätere Detailansicht für Vorschau, Teileliste und Bauplan",
                "Wiederöffnung generierter oder gesicherter Projekte"
            ],
            accentColor: .green
        )
        .navigationTitle("Projekte")
    }
}

#Preview {
    NavigationStack {
        ProjectDetailView()
    }
}

