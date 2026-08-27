import Testing
import MurtiCore
@testable import MurtiBuilder

@Suite("Button + Action")
struct ButtonActionTests {
    @Test func navigateButton() {
        let n = Button("Go", action: .navigate("detail", params: ["id": "1"])).node()
        #expect(n.type == "button")
        #expect(n.string("title") == "Go")
        #expect(n.action?.type == .navigate)
        #expect(n.action?.screen == "detail")
        #expect(n.action?.params?["id"] == .string("1"))
    }
    @Test func apiWithChain() {
        let a = Action.api("getBalance", onSuccess: .navigate("balance"))
        #expect(a.spec.type == .api)
        #expect(a.spec.request == "getBalance")
        #expect(a.spec.onSuccess?.type == .navigate)
    }
    @Test func simpleActions() {
        #expect(Action.dismiss.spec.type == .dismiss)
        #expect(Action.refresh.spec.type == .refresh)
        #expect(Action.openURL("help").spec.link == "help")
    }
    @Test func buttonWithoutAction() {
        #expect(Button("Plain").node().action == nil)
    }
}
