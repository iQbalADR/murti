import Foundation
import Testing
@testable import MurtiCore

@MainActor
@Suite("MurtiEngine.load & MurtiScreenFactory")
struct MurtiEngineTests {
    private func engine(_ screenFactory: MurtiScreenFactory = MurtiScreenFactory()) -> MurtiEngine {
        MurtiEngine(componentFactory: .withBuiltins, screenFactory: screenFactory)
    }

    private static func fixture(_ relativePath: String, file: String = #filePath) -> URL {
        URL(filePath: file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "docs/fixtures/\(relativePath)")
    }

    @Test func loadsInlinePayload() async {
        let data = Data(#"{ "schemaVersion": "1.0", "screen": { "key": "s", "root": { "type": "vstack" } } }"#.utf8)
        guard case .loaded(let root) = await engine().load(.inline(data)) else {
            Issue.record("expected .loaded"); return
        }
        #expect(root.type == "vstack")
    }

    @Test func loadsRegisteredKey() async {
        let factory = MurtiScreenFactory()
        factory.register("home", data: Data(#"{"schemaVersion":"1.0","screen":{"key":"home","root":{"type":"text"}}}"#.utf8))
        guard case .loaded(let root) = await engine(factory).load(.key("home")) else {
            Issue.record("expected .loaded"); return
        }
        #expect(root.type == "text")
    }

    @Test func unknownKeyFailsClosed() async {
        #expect(await engine().load(.key("ghost")) == .failed(.unknownScreen("ghost")))
    }

    @Test func namedWithoutResolverFailsClosed() async {
        #expect(await engine().load(.named("remote")) == .failed(.unknownScreen("remote")))
    }

    @Test func garbageFailsClosedWithoutCrashing() async {
        if case .failed = await engine().load(.inline(Data("not json".utf8))) {} else {
            Issue.record("expected .failed")
        }
    }

    @Test func loadsDashboardFixture() async throws {
        let data = try Data(contentsOf: Self.fixture("valid/dashboard.json"))
        guard case .loaded(let root) = await engine().load(.inline(data)) else {
            Issue.record("expected .loaded"); return
        }
        #expect(root.type == "vstack")
        #expect(root.children.count == 3)
    }

    @Test func loadRejectsDecodeCleanButInvalidFixture() async throws {
        // navigate-without-screen decodes fine, but validation rejects it.
        let data = try Data(contentsOf: Self.fixture("invalid/navigate_missing_screen.json"))
        if case .failed(.schema) = await engine().load(.inline(data)) {} else {
            Issue.record("expected .failed(.schema)")
        }
    }

    @Test func screenFactoryReportsRegisteredKeys() {
        let factory = MurtiScreenFactory()
        factory.register("a", data: Data("{}".utf8)).register("b", data: Data("{}".utf8))
        #expect(factory.registeredKeys == ["a", "b"])
    }

    @Test func screenConstructsWithInlineSource() {
        _ = MurtiScreen(
            .inline(Data(#"{"schemaVersion":"1.0","screen":{"key":"s","root":{"type":"text"}}}"#.utf8)),
            engine: engine()
        )
    }
}
