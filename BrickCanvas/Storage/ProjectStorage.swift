import Foundation

struct ProjectSaveRequest: Hashable, Sendable {
    let project: BrickCanvasProject
}

struct ProjectStorageSummary: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let name: String
    let lifecycle: ProjectLifecycle
    let updatedAt: Date
}

protocol ProjectStorage: Sendable {
    func save(_ request: ProjectSaveRequest) async throws
    func loadProject(id: UUID) async throws -> BrickCanvasProject
    func listProjects() async throws -> [ProjectStorageSummary]
    func deleteProject(id: UUID) async throws
}

