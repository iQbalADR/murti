import Foundation

/// The plaintext screen tree — the payload inside the envelope, or posted
/// directly during development.
public struct MurtiPayload: Sendable, Hashable, Codable {
    public let schemaVersion: String
    public let screen: MurtiScreenSpec

    public init(schemaVersion: String, screen: MurtiScreenSpec) {
        self.schemaVersion = schemaVersion
        self.screen = screen
    }
}

/// A named screen and its root node. `key` must resolve in the screen factory —
/// a semantic check, not a decode concern.
public struct MurtiScreenSpec: Sendable, Hashable, Codable {
    public let key: String
    public let root: MurtiNode

    public init(key: String, root: MurtiNode) {
        self.key = key
        self.root = root
    }
}

/// The production transport wrapper. The client verifies the signature (and
/// optionally decrypts) BEFORE trusting the payload. This type only models the
/// envelope shape; verification/decryption is the crypto layer's job.
///
/// `payload` and `signature` decode from base64 automatically (the JSON decoder's
/// default data strategy).
public struct MurtiEnvelope: Sendable, Hashable, Codable {
    public let schemaVersion: String
    public let alg: String
    public let enc: String?
    public let payload: Data
    public let signature: Data

    public init(schemaVersion: String, alg: String, enc: String? = nil, payload: Data, signature: Data) {
        self.schemaVersion = schemaVersion
        self.alg = alg
        self.enc = enc
        self.payload = payload
        self.signature = signature
    }
}
