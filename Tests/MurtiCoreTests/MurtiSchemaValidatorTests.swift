import Foundation
import Testing
@testable import MurtiCore

@Suite("MurtiSchemaValidator")
struct MurtiSchemaValidatorTests {
    private let validator = MurtiSchemaValidator()

    private static func fixture(_ relativePath: String, file: String = #filePath) -> URL {
        URL(filePath: file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "docs/fixtures/\(relativePath)")
    }

    private func payload(_ name: String) throws -> MurtiPayload {
        try JSONDecoder().decode(MurtiPayload.self, from: Data(contentsOf: Self.fixture(name)))
    }

    private func rootPayload(_ root: MurtiNode) -> MurtiPayload {
        MurtiPayload(schemaVersion: "1.0", screen: MurtiScreenSpec(key: "s", root: root))
    }

    // MARK: - Valid fixtures

    @Test("valid fixtures pass validation", arguments: [
        "valid/dashboard.json", "valid/login.json", "valid/error_state.json", "valid/third_party_lottie.json",
    ])
    func validFixturesPass(_ name: String) throws {
        try validator.validate(try payload(name))
    }

    // MARK: - Schema conformance (decode-clean but invalid)

    @Test func navigateWithoutScreenIsRejected() throws {
        let action = MurtiActionSpec(type: .navigate)   // no screen
        let node = MurtiNode(type: "button", action: action)
        #expect(throws: MurtiError.self) { try validator.validate(rootPayload(node)) }
    }

    @Test func openURLWithRawURLIsRejected() throws {
        let action = MurtiActionSpec(type: .openURL, link: "https://evil.example.com")
        let node = MurtiNode(type: "button", action: action)
        #expect(throws: MurtiError.self) { try validator.validate(rootPayload(node)) }
    }

    @Test func badSchemaVersionIsRejected() {
        let payload = MurtiPayload(schemaVersion: "1", screen: MurtiScreenSpec(key: "s", root: MurtiNode(type: "text")))
        #expect(throws: MurtiError.self) { try validator.validate(payload) }
    }

    @Test func unsupportedMajorVersionIsRejected() {
        let payload = MurtiPayload(schemaVersion: "2.0", screen: MurtiScreenSpec(key: "s", root: MurtiNode(type: "text")))
        #expect(throws: MurtiError.unsupportedVersion("2.0")) { try validator.validate(payload) }
    }

    // MARK: - Bounds (tailored small limits)

    @Test func stringLengthBound() {
        let v = MurtiSchemaValidator(bounds: MurtiBounds(maxStringLength: 4))
        let node = MurtiNode(type: "text", props: ["value": .string("toolong")])
        #expect(throws: MurtiError.self) { try v.validate(root: node) }
    }

    @Test func treeDepthBound() {
        let v = MurtiSchemaValidator(bounds: MurtiBounds(maxDepth: 3))
        var node = MurtiNode(type: "text")
        for _ in 0..<4 { node = MurtiNode(type: "vstack", children: [node]) }  // depth 5
        #expect(throws: MurtiError.self) { try v.validate(root: node) }
    }

    @Test func childrenCountBound() {
        let v = MurtiSchemaValidator(bounds: MurtiBounds(maxChildren: 2))
        let node = MurtiNode(type: "vstack", children: (0..<3).map { _ in MurtiNode(type: "text") })
        #expect(throws: MurtiError.self) { try v.validate(root: node) }
    }

    @Test func totalNodeBound() {
        let v = MurtiSchemaValidator(bounds: MurtiBounds(maxNodes: 5))
        let node = MurtiNode(type: "vstack", children: (0..<6).map { _ in MurtiNode(type: "text") })  // 7 nodes
        #expect(throws: MurtiError.self) { try v.validate(root: node) }
    }

    @Test func actionChainDepthBound() {
        let v = MurtiSchemaValidator(bounds: MurtiBounds(maxChainDepth: 2))
        var action = MurtiActionSpec(type: .refresh)
        for _ in 0..<3 { action = MurtiActionSpec(type: .navigate, screen: "s", onSuccess: action) }
        let node = MurtiNode(type: "button", action: action)
        #expect(throws: MurtiError.self) { try v.validate(root: node) }
    }

    @Test func arrayItemsBound() {
        let v = MurtiSchemaValidator(bounds: MurtiBounds(maxArrayItems: 2))
        let node = MurtiNode(type: "text", props: ["tags": .array([.number(1), .number(2), .number(3)])])
        #expect(throws: MurtiError.self) { try v.validate(root: node) }
    }

    @Test func validNodeWithinDefaultsPasses() throws {
        let node = MurtiNode(
            type: "vstack",
            props: ["spacing": .number(12)],
            children: [MurtiNode(type: "text", props: ["value": .string("hi")])],
            action: nil
        )
        try validator.validate(root: node)
    }
}
