import Foundation
import SwiftUI
import Testing
@testable import MurtiCore

@MainActor
@Suite("MurtiComponentFactory")
struct MurtiComponentFactoryTests {
    @Test func registersAndResolvesByType() {
        let factory = MurtiComponentFactory()
        factory.register(TextComponent())
        #expect(factory.component(for: "text") != nil)
        #expect(factory.component(for: "unregistered") == nil)
    }

    @Test func closureRegistrationWrapsAnyViewInline() {
        // Wrapping a library/view is one call — no new type, no new module.
        let factory = MurtiComponentFactory()
        factory.register("gauge") { node, context in
            Text(context.resolve(node.string("label")))
        }
        #expect(factory.component(for: "gauge") != nil)
        #expect(factory.registeredTypes.contains("gauge"))
        // Still renders through the one registry + render path.
        _ = MurtiRenderer(factory: factory).render(MurtiNode(type: "gauge", props: ["label": .string("hi")]))
    }

    @Test func builtinsAreAllRegistered() {
        let factory = MurtiComponentFactory.withBuiltins
        #expect(factory.registeredTypes == ["button", "card", "hstack", "image", "text", "vstack"])
    }

    @Test func lastRegistrationWinsForSameType() {
        let factory = MurtiComponentFactory()
        factory.register(TextComponent())
        factory.register(TextComponent())
        #expect(factory.registeredTypes == ["text"])
    }
}
