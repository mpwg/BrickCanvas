import SwiftUI

struct PlaceholderScreen: View {
    let eyebrow: String
    let title: String
    let message: String
    let bullets: [String]
    let accentColor: Color

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(eyebrow.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(accentColor)

                    Text(title)
                        .font(.largeTitle.weight(.bold))

                    Text(message)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(bullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(accentColor)
                                .padding(.top, 6)

                            Text(bullet)
                                .font(.body)
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(accentColor.opacity(0.12))
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    PlaceholderScreen(
        eyebrow: "Vorschau",
        title: "Platzhalter",
        message: "Dieses Gerüst definiert nur Navigation und Screen-Verantwortung.",
        bullets: ["Einfacher SwiftUI-Startpunkt", "Klar getrennte Feature-Screens"],
        accentColor: .orange
    )
}

