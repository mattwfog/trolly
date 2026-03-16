import Testing
import Foundation
@testable import Trolly

@Suite("Script")
struct ScriptTests {

    @Test("create sets id, timestamps, and content")
    func testCreate() {
        let before = Date()
        let script = Script.create(title: "Test", content: "Hello world")
        let after = Date()

        #expect(script.title == "Test")
        #expect(script.content == "Hello world")
        #expect(script.createdAt >= before)
        #expect(script.createdAt <= after)
        #expect(script.updatedAt >= before)
        #expect(script.updatedAt <= after)
    }

    @Test("withTitle returns new script with updated title")
    func testWithTitle() {
        let original = Script.create(title: "Old", content: "Content")
        let updated = original.withTitle("New")

        #expect(updated.title == "New")
        #expect(original.title == "Old")
        #expect(updated.id == original.id)
        #expect(updated.content == original.content)
    }

    @Test("withContent returns new script with updated content")
    func testWithContent() {
        let original = Script.create(title: "Title", content: "Old content")
        let updated = original.withContent("New content")

        #expect(updated.content == "New content")
        #expect(original.content == "Old content")
        #expect(updated.id == original.id)
        #expect(updated.title == original.title)
    }

    @Test("withTitle updates updatedAt timestamp")
    func testWithTitleUpdatesTimestamp() throws {
        let original = Script(
            id: UUID(),
            title: "Title",
            content: "Content",
            createdAt: Date(timeIntervalSince1970: 1000),
            updatedAt: Date(timeIntervalSince1970: 1000)
        )
        let updated = original.withTitle("New")

        #expect(updated.updatedAt > original.updatedAt)
        #expect(updated.createdAt == original.createdAt)
    }

    @Test("Codable round-trip preserves all fields")
    func testCodableRoundTrip() throws {
        let script = Script.create(title: "My Script", content: "Line one\nLine two")
        let data = try JSONEncoder().encode(script)
        let decoded = try JSONDecoder().decode(Script.self, from: data)

        #expect(decoded == script)
    }
}
