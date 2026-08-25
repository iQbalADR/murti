import Foundation
import Testing
@testable import MurtiCore

@Suite("TokenResolver")
struct TokenResolverTests {
    private let data: [String: MurtiValue] = [
        "name": .string("Ada"),
        "count": .number(3),
        "user": .object(["name": .string("Grace")]),
    ]

    private func lookup(_ path: String) -> MurtiValue? {
        let parts = path.split(separator: ".").map(String.init)
        guard let first = parts.first else { return nil }
        var current = data[first]
        for part in parts.dropFirst() {
            guard case .object(let object)? = current else { return nil }
            current = object[part]
        }
        return current
    }

    @Test func replacesSimpleToken() {
        #expect(TokenResolver.resolve("Hi {{name}}", lookup: lookup) == "Hi Ada")
    }
    @Test func replacesNestedPath() {
        #expect(TokenResolver.resolve("{{user.name}}", lookup: lookup) == "Grace")
    }
    @Test func numberTokenUsesDisplayString() {
        #expect(TokenResolver.resolve("n={{count}}", lookup: lookup) == "n=3")
    }
    @Test func missingTokenResolvesEmpty() {
        #expect(TokenResolver.resolve("[{{nope}}]", lookup: lookup) == "[]")
    }
    @Test func multipleTokens() {
        #expect(TokenResolver.resolve("{{name}}/{{count}}", lookup: lookup) == "Ada/3")
    }
    @Test func whitespaceInsideBracesIsTrimmed() {
        #expect(TokenResolver.resolve("{{ name }}", lookup: lookup) == "Ada")
    }
    @Test func noTokensPassThrough() {
        #expect(TokenResolver.resolve("plain text", lookup: lookup) == "plain text")
    }
    @Test func unterminatedTokenIsLiteral() {
        #expect(TokenResolver.resolve("a {{oops", lookup: lookup) == "a {{oops")
    }
}
