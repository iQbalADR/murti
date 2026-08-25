import CryptoKit
import Foundation

/// Opt-in AES-GCM encryption for cached bytes. The adopter owns the key (create
/// or load it from the Keychain / Secure Enclave and pass it in).
public struct AESGCMCipher: MurtiCacheCipher {
    private let key: SymmetricKey
    public init(key: SymmetricKey) { self.key = key }

    public func seal(_ plaintext: Data) throws -> Data {
        guard let combined = try AES.GCM.seal(plaintext, using: key).combined else {
            throw MurtiError.decryptionFailed
        }
        return combined
    }

    public func open(_ ciphertext: Data) throws -> Data {
        try AES.GCM.open(AES.GCM.SealedBox(combined: ciphertext), using: key)
    }
}
