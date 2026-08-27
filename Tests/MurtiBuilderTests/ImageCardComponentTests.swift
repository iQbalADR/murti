import Testing
import MurtiCore
@testable import MurtiBuilder

@Suite("Image / Card / component")
struct ImageCardComponentTests {
    @Test func imageSystemName() {
        #expect(Image(systemName: "star.fill").node().string("systemName") == "star.fill")
    }
    @Test func imageAsset() {
        let n = Image(name: "logo", contentMode: "fit").node()
        #expect(n.string("name") == "logo")
        #expect(n.string("contentMode") == "fit")
    }
    @Test func card() {
        let n = Card(padding: 16) { Text("hi") }.node()
        #expect(n.type == "card")
        #expect(n.int("padding") == 16)
        #expect(n.children.count == 1)
    }
    @Test func customComponent() {
        let n = component("rating", ["stars": 4]).node()
        #expect(n.type == "rating")
        #expect(n.int("stars") == 4)
    }
    @Test func customComponentWithChildren() {
        let n = component("carousel", ["loop": true]) { Text("a"); Text("b") }.node()
        #expect(n.type == "carousel")
        #expect(n.bool("loop") == true)
        #expect(n.children.count == 2)
    }
}
