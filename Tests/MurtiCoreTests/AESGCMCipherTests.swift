import CryptoKit
import Foundation
import Testing
@testable import MurtiCore

@Suite("AESGCMCipher")
struct AESGCMCipherTests {
    @Test func roundTripsAndHidesPlaintext() throws {
        let cipher = AESGCMCipher(key: SymmetricKey(size: .bits256))
        let data = Data("secret payload".utf8)
        let sealed = try cipher.seal(data)
        #expect(sealed != data)
        #expect(try cipher.open(sealed) == data)
    }
    @Test func wrongKeyFailsToOpen() throws {
        let sealed = try AESGCMCipher(key: SymmetricKey(size: .bits256)).seal(Data("x".utf8))
        #expect(throws: (any Error).self) { try AESGCMCipher(key: SymmetricKey(size: .bits256)).open(sealed) }
    }
}
