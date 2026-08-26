import Foundation
import Testing
@testable import MurtiCore

@Suite("MurtiCacheCipher")
struct MurtiCacheCipherTests {
    @Test func passthroughRoundTripsIdentity() throws {
        let cipher = PassthroughCipher()
        let data = Data("hello".utf8)
        #expect(try cipher.seal(data) == data)
        #expect(try cipher.open(cipher.seal(data)) == data)
    }
}
