import Foundation

/// At-rest encryption for cached bytes (Strategy). The default is a no-op;
/// adopters flip on an encrypting implementation when payloads are sensitive.
public protocol MurtiCacheCipher: Sendable {
    func seal(_ plaintext: Data) throws -> Data
    func open(_ ciphertext: Data) throws -> Data
}

/// No encryption — cached bytes are stored as-is (still OS Data-Protected on disk).
public struct PassthroughCipher: MurtiCacheCipher {
    public init() {}
    public func seal(_ plaintext: Data) throws -> Data { plaintext }
    public func open(_ ciphertext: Data) throws -> Data { ciphertext }
}
