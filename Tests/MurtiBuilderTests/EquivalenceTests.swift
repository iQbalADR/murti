import Foundation
import Testing
import MurtiCore
@testable import MurtiBuilder

@MainActor
@Suite("DSL equivalence + render")
struct EquivalenceTests {
    private static func fixture(_ name: String, file: String = #filePath) -> URL {
        URL(filePath: file)
            .deletingLastPathComponent()   // MurtiBuilderTests
            .deletingLastPathComponent()   // Tests
            .deletingLastPathComponent()   // repo root
            .appending(path: "docs/fixtures/valid/\(name)")
    }

    // Rebuild docs/fixtures/valid/dashboard.json in the DSL.
    private func dashboard() -> Screen {
        Screen("dashboard") {
            VStack(spacing: 12, alignment: .leading) {
                Text("Hello, {{user.name}}", style: .title)
                Button("View details",
                       action: .navigate("productDetail", params: ["productId": "abc123"]),
                       a11yId: "details_button")
                Button("Load balance",
                       action: .api("getAccountBalance", onSuccess: .navigate("balanceDetail")))
            }
        }
    }

    @Test func matchesHandWrittenFixture() throws {
        let data = try Data(contentsOf: Self.fixture("dashboard.json"))
        let hand = try JSONDecoder().decode(MurtiPayload.self, from: data)
        let root = dashboard().payload.screen.root
        #expect(root.type == hand.screen.root.type)
        #expect(root.children.count == hand.screen.root.children.count)
        #expect(root.children.map(\.type) == hand.screen.root.children.map(\.type))
    }

    @Test func dslOutputRenders() {
        let renderer = MurtiRenderer(factory: .withBuiltins)
        _ = renderer.render(dashboard().payload.screen.root,
                            data: DataContext(["user": .object(["name": .string("Ada")])]))
    }
}
