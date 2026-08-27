import Foundation
import Testing
import MurtiBuilder
import MurtiCore
@testable import MurtiGen

@Suite("ScreenBundle")
struct ScreenBundleTests {
    private func screens() -> [Screen] {
        [ Screen("home") { VStack { Text("Hi") } },
          Screen("about") { Text("About") } ]
    }
    @Test func emitsValidatedFilesKeyedByScreen() throws {
        let files = try ScreenBundle(screens: screens()).files()
        #expect(files.map(\.name).sorted() == ["about.json", "home.json"])
        for file in files {
            let payload = try JSONDecoder().decode(MurtiPayload.self, from: file.data)
            #expect(file.name == "\(payload.screen.key).json")
        }
    }
    @Test func invalidScreenFailsTheBundle() {
        let bad = [Screen("s") { Button("x", action: .openURL("https://evil.example.com")) }]
        #expect(throws: (any Error).self) { try ScreenBundle(screens: bad).files() }
    }
}
