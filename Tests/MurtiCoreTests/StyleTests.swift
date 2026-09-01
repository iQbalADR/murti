import Testing
import SwiftUI
@testable import MurtiCore

@Suite("Bounded style props")
struct StyleTests {
    @Test func parsesSixDigitHex() {
        let c = murtiParseHexColor("#FF8000")
        #expect(c != nil)
        #expect(abs(c!.red - 1.0) < 1e-9)
        #expect(abs(c!.green - Double(0x80) / 255) < 1e-9)
        #expect(abs(c!.blue - 0.0) < 1e-9)
        #expect(c!.alpha == 1.0)
    }

    @Test func parsesShorthandAndAlphaAndBareHex() {
        #expect(murtiParseHexColor("#FFF") == MurtiRGBA(red: 1, green: 1, blue: 1, alpha: 1))
        #expect(murtiParseHexColor("00FF00") == MurtiRGBA(red: 0, green: 1, blue: 0, alpha: 1))
        let a = murtiParseHexColor("#00000080")
        #expect(a != nil)
        #expect(abs(a!.alpha - Double(0x80) / 255) < 1e-9)
    }

    @Test func rejectsNonHex() {
        #expect(murtiParseHexColor("") == nil)
        #expect(murtiParseHexColor("nope") == nil)
        #expect(murtiParseHexColor("#12345") == nil)   // 5 digits isn't a valid length
        #expect(Color(murtiHex: "rgb(1,2,3)") == nil)
    }

    @Test func knownFontWeightsResolve() {
        #expect(murtiFontWeight("bold") == .bold)
        #expect(murtiFontWeight("semibold") == .semibold)
        #expect(murtiFontWeight("nope") == nil)
    }

    @MainActor
    @Test func styledNodesRenderWithoutCrashing() {
        let renderer = MurtiRenderer(factory: .withBuiltins)
        let node = MurtiNode(type: "card", props: [
            "background": .string("#EB6D00"),
            "cornerRadius": .number(16),
            "padding": .number(20),
            "foreground": .string("#FFFFFF"),
        ], children: [
            MurtiNode(type: "text", props: [
                "value": .string("Balance"),
                "color": .string("#FFFFFF"),
                "weight": .string("bold"),
                "size": .number(28),
            ]),
        ])
        _ = renderer.render(node)
    }
}
