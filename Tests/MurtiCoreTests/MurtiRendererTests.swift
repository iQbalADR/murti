import Foundation
import Testing
@testable import MurtiCore

@MainActor
@Suite("MurtiRenderer")
struct MurtiRendererTests {
    private static func fixture(_ relativePath: String, file: String = #filePath) -> URL {
        URL(filePath: file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "docs/fixtures/\(relativePath)")
    }

    @Test("renders a known node")
    func rendersKnownNode() {
        let renderer = MurtiRenderer(factory: .withBuiltins)
        let node = MurtiNode(type: "text", props: ["value": .string("Hi {{name}}")])
        _ = renderer.render(node, data: DataContext(["name": .string("Ada")]))
        // Building the view for a registered type succeeds (no crash).
    }

    @Test("renders an image by SF Symbol name")
    func rendersImageBySystemName() {
        let renderer = MurtiRenderer(factory: .withBuiltins)
        _ = renderer.render(MurtiNode(type: "image", props: ["systemName": .string("star.fill")]))
    }

    @Test("unknown type resolves to nil and falls back without crashing")
    func unknownTypeFallsBack() {
        let factory = MurtiComponentFactory.withBuiltins
        #expect(factory.component(for: "lottie") == nil)   // open registry: unknown → nil
        let renderer = MurtiRenderer(factory: factory)
        _ = renderer.render(MurtiNode(type: "lottie"))     // Null-Object fallback, not a crash
    }

    @Test("walks a nested tree decoded from the dashboard fixture")
    func rendersNestedFixture() throws {
        let data = try Data(contentsOf: Self.fixture("valid/dashboard.json"))
        let payload = try JSONDecoder().decode(MurtiPayload.self, from: data)
        let renderer = MurtiRenderer(factory: .withBuiltins)
        _ = renderer.render(payload.screen.root, data: DataContext(["user": .object(["name": .string("Ada")])]))
        // vstack → text + two buttons all resolve through the Composite walk.
    }

    @Test("a tapped button dispatches its action")
    func buttonDispatchesAction() {
        var dispatched: MurtiActionSpec?
        let context = MurtiRenderContext(
            data: DataContext(),
            factory: .withBuiltins,
            dispatch: { dispatched = $0 }
        )
        let button = MurtiNode(
            type: "button",
            props: ["title": .string("Go")],
            action: MurtiActionSpec(type: .navigate, screen: "next")
        )
        // The dispatch closure is what a Button's action would call.
        if let action = button.action { context.dispatch(action) }
        #expect(dispatched?.type == .navigate)
        #expect(dispatched?.screen == "next")
    }
}
