import Foundation
import Testing
import MurtiCore
@testable import MurtiBuilder

@Suite("Screen")
struct ScreenTests {
    private func sample() -> Screen {
        Screen("dashboard") {
            VStack(spacing: 12, alignment: .leading) {
                Text("Hello, {{user.name}}", style: .title)
                Button("Go", action: .navigate("detail", params: ["id": "1"]))
            }
        }
    }
    @Test func buildsPayload() {
        let p = sample().payload
        #expect(p.schemaVersion == "1.0")
        #expect(p.screen.key == "dashboard")
        #expect(p.screen.root.type == "vstack")
        #expect(p.screen.root.children.count == 2)
    }
    @Test func validatesAndEncodes() throws {
        let data = try sample().validated().jsonData()
        let decoded = try JSONDecoder().decode(MurtiPayload.self, from: data)
        #expect(decoded == sample().payload)          // round-trips
    }
    @Test func invalidScreenThrowsOnValidate() {
        // openURL with a raw URL is rejected by the validator (link must be an identifier).
        let bad = Screen("s") { Button("x", action: .openURL("https://evil.example.com")) }
        #expect(throws: MurtiError.self) { try bad.validated() }
    }
}
