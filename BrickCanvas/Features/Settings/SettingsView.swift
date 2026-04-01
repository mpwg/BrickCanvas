import SwiftUI

struct SettingsView: View {
    var body: some View {
        PlaceholderScreen(
            eyebrow: "App",
            title: "Einstellungen",
            message: "Hier landen globale App-Einstellungen und später auch mögliche Projekt-Defaults aus dem MVP-Flow.",
            bullets: [
                "Globale Standardwerte",
                "Spätere Export- und Anzeigepräferenzen",
                "Klärung, welche Defaults projektweit gelten dürfen"
            ],
            accentColor: .purple
        )
        .navigationTitle("Einstellungen")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}

