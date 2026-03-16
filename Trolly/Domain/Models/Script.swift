import Foundation

struct Script: Codable, Equatable, Sendable, Identifiable {
    let id: UUID
    let title: String
    let content: String
    let createdAt: Date
    let updatedAt: Date

    static func create(title: String, content: String) -> Script {
        let now = Date()
        return Script(
            id: UUID(),
            title: title,
            content: content,
            createdAt: now,
            updatedAt: now
        )
    }

    func withTitle(_ title: String) -> Script {
        Script(
            id: id,
            title: title,
            content: content,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }

    func withContent(_ content: String) -> Script {
        Script(
            id: id,
            title: title,
            content: content,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
}
