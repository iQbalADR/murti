import Foundation
import Testing
@testable import MurtiCore

@Suite("Manifest")
struct ManifestTests {
    @Test func decodes() throws {
        let json = Data(#"{ "sequence": 7, "screens": { "dashboard": "v7", "login": "v3" } }"#.utf8)
        let m = try JSONDecoder().decode(Manifest.self, from: json)
        #expect(m.sequence == 7)
        #expect(m.screens["dashboard"] == "v7")
    }
}
