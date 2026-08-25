import Foundation
import Testing
@testable import MurtiCore

@Suite("MurtiActionSpec")
struct MurtiActionSpecTests {
    @Test("navigate carries screen + params")
    func navigate() throws {
        let json = Data("""
        { "type": "navigate", "screen": "productDetail",
          "params": { "productId": "abc123" } }
        """.utf8)
        let action = try JSONDecoder().decode(MurtiActionSpec.self, from: json)
        #expect(action.type == .navigate)
        #expect(action.screen == "productDetail")
        #expect(action.params?["productId"] == .string("abc123"))
        #expect(action.onSuccess == nil)
    }

    @Test("api carries a linear onSuccess chain")
    func chain() throws {
        let json = Data("""
        { "type": "api", "request": "getAccountBalance",
          "onSuccess": { "type": "navigate", "screen": "balanceDetail" } }
        """.utf8)
        let action = try JSONDecoder().decode(MurtiActionSpec.self, from: json)
        #expect(action.type == .api)
        #expect(action.request == "getAccountBalance")
        #expect(action.onSuccess?.type == .navigate)
        #expect(action.onSuccess?.screen == "balanceDetail")
    }

    @Test("unknown action type is rejected (closed vocabulary)")
    func unknownType() {
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(MurtiActionSpec.self, from: Data(#"{ "type": "eval" }"#.utf8))
        }
    }

    @Test("the action vocabulary has exactly five members")
    func vocabulary() {
        #expect(ActionType.allCases.count == 5)
    }

    @Test("round-trips through JSON preserving the chain")
    func roundTrip() throws {
        let action = MurtiActionSpec(
            type: .api, request: "r",
            onSuccess: MurtiActionSpec(type: .navigate, screen: "next")
        )
        let data = try JSONEncoder().encode(action)
        let back = try JSONDecoder().decode(MurtiActionSpec.self, from: data)
        #expect(back == action)
        #expect(back.onSuccess?.screen == "next")
    }
}
