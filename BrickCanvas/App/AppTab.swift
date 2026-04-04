import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case newProject
    case projects
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home:
            "Start"
        case .newProject:
            "Neues Projekt"
        case .projects:
            "Projekte"
        case .settings:
            "Einstellungen"
        }
    }

    var systemImage: String {
        switch self {
        case .home:
            "house"
        case .newProject:
            "plus.square.on.square"
        case .projects:
            "square.grid.2x2"
        case .settings:
            "gearshape"
        }
    }

    @MainActor
    @ViewBuilder
    var rootView: some View {
        switch self {
        case .home:
            HomeView()
        case .newProject:
            NewProjectView()
        case .projects:
            ProjectDetailView()
        case .settings:
            SettingsView()
        }
    }
}
