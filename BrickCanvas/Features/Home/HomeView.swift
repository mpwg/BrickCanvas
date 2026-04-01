import SwiftUI

struct HomeView: View {
    var body: some View {
        PlaceholderScreen(
            eyebrow: "BrickCanvas",
            title: "Start",
            message: "Der Home-Screen wird später Einstieg, letzte Projekte und den primären CTA für neue Mosaike bündeln.",
            bullets: [
                "Primärer Einstieg in den MVP-Flow",
                "Platz für letzte oder gespeicherte Projekte",
                "Schnellzugriff auf neues Projekt und Einstellungen"
            ],
            accentColor: .orange
        )
        .navigationTitle("BrickCanvas")
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}

