import Foundation
import Testing
@testable import MurtiCore

@MainActor
@Suite("DataContext")
struct DataContextTests {
    @Test func seedAndNestedLookup() {
        let context = DataContext(["user": .object(["name": .string("Ada")])])
        #expect(context.value(forKeyPath: "user.name") == .string("Ada"))
        #expect(context["user"] != nil)
        #expect(context.value(forKeyPath: "user.missing") == nil)
    }

    @Test func mergeUpdatesValues() {
        let context = DataContext()
        context.merge(["balance": .number(100)])
        #expect(context.value(forKeyPath: "balance") == .number(100))
    }

    @Test func resolvesTokens() {
        let context = DataContext(["name": .string("Ada")])
        #expect(context.resolve("Hi {{name}}") == "Hi Ada")
    }

    @Test func childScopeDoesNotLeakIntoParent() {
        let parent = DataContext(["a": .number(1)])
        let child = MurtiRenderContext(data: parent)
            .child(merging: ["a": .number(2), "b": .number(9)])
        #expect(child.data.value(forKeyPath: "a") == .number(2))
        #expect(child.data.value(forKeyPath: "b") == .number(9))
        #expect(parent.value(forKeyPath: "a") == .number(1))
        #expect(parent.value(forKeyPath: "b") == nil)
    }
}
