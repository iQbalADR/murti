import Foundation
import Testing
@testable import MurtiCore

/// Decodes the repository's shared `docs/fixtures/` through the Swift model, so
/// the JSON Schema, the example payloads, and the types can never silently drift
/// apart.
@Suite("Fixture decoding")
struct FixtureDecodingTests {
    /// Repo root, from this file at <root>/Tests/MurtiCoreTests/FixtureDecodingTests.swift
    private static func fixture(_ relativePath: String, file: String = #filePath) -> URL {
        URL(filePath: file)
            .deletingLastPathComponent()   // MurtiCoreTests
            .deletingLastPathComponent()   // Tests
            .deletingLastPathComponent()   // repo root
            .appending(path: "docs/fixtures/\(relativePath)")
    }

    @Test("valid payload fixtures decode into the model", arguments: [
        "dashboard.json", "login.json", "error_state.json", "third_party_lottie.json",
    ])
    func decodesValidPayloads(_ name: String) throws {
        let data = try Data(contentsOf: Self.fixture("valid/\(name)"))
        let payload = try JSONDecoder().decode(MurtiPayload.self, from: data)
        #expect(payload.schemaVersion == "1.0")
        #expect(!payload.screen.key.isEmpty)
        #expect(!payload.screen.root.type.isEmpty)
    }

    @Test("envelope decodes, and so does its inner payload")
    func decodesEnvelope() throws {
        let data = try Data(contentsOf: Self.fixture("valid/envelope.json"))
        let envelope = try JSONDecoder().decode(MurtiEnvelope.self, from: data)
        #expect(envelope.alg == "ed25519")
        #expect(!envelope.payload.isEmpty)
        let inner = try JSONDecoder().decode(MurtiPayload.self, from: envelope.payload)
        #expect(inner.screen.key == "s")
    }

    @Test("structurally invalid fixtures are rejected at the decode layer", arguments: [
        "missing_type.json", "action_unknown_type.json",
    ])
    func rejectsStructurallyInvalid(_ name: String) throws {
        let data = try Data(contentsOf: Self.fixture("invalid/\(name)"))
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(MurtiPayload.self, from: data)
        }
    }
}
