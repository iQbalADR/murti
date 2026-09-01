import Testing
import SwiftUI
@testable import MurtiCore

@Suite("ZStack absolute layout")
struct LayoutTests {
    @Test func childBoxUsesPositionProps() {
        let child = MurtiNode(type: "image", props: [
            "x": .number(10), "y": .number(20), "width": .number(100), "height": .number(50),
        ])
        #expect(childBox(child, frameWidth: 375, frameHeight: 812) == CGRect(x: 10, y: 20, width: 100, height: 50))
    }

    @Test func childBoxFallsBackToFrameSize() {
        let child = MurtiNode(type: "image", props: [:])
        #expect(childBox(child, frameWidth: 375, frameHeight: 812) == CGRect(x: 0, y: 0, width: 375, height: 812))
    }

    @MainActor
    @Test func absoluteZStackRendersWithoutCrashing() {
        let renderer = MurtiRenderer(factory: .withBuiltins)
        let node = MurtiNode(type: "zstack", props: ["width": .number(375), "height": .number(812)], children: [
            MurtiNode(type: "image", props: ["x": .number(0), "y": .number(0), "width": .number(375), "height": .number(812)]),
            MurtiNode(type: "text", props: [
                "value": .string("Log in"), "x": .number(20), "y": .number(740), "width": .number(150), "height": .number(44),
            ]),
        ])
        _ = renderer.render(node)
    }

    @MainActor
    @Test func sizelessZStackRendersAsOverlay() {
        let renderer = MurtiRenderer(factory: .withBuiltins)
        _ = renderer.render(MurtiNode(type: "zstack", children: [
            MurtiNode(type: "text", props: ["value": .string("centered")]),
        ]))
    }
}
