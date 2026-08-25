import CryptoKit
import Foundation

/// Verifies a detached signature over payload bytes (Strategy). The server signs
/// with its PRIVATE key; the app verifies with the EMBEDDED PUBLIC key, and
/// rejects on mismatch. Signing lives server-side and is intentionally NOT part
/// of the client framework.
public protocol MurtiSignatureVerifier: Sendable {
    func verify(payload: Data, signature: Data) -> Bool
}

/// Ed25519 verifier (CryptoKit) — the schema's default `alg`. Stores the public
/// key's raw representation (validated at init) so it stays a `Sendable` value.
public struct Ed25519Verifier: MurtiSignatureVerifier {
    private let publicKeyData: Data

    /// - Parameter publicKey: the 32-byte Ed25519 public key (raw representation),
    ///   embedded in the app.
    public init(publicKey rawRepresentation: Data) throws {
        _ = try Curve25519.Signing.PublicKey(rawRepresentation: rawRepresentation)  // validate now
        self.publicKeyData = rawRepresentation
    }

    public func verify(payload: Data, signature: Data) -> Bool {
        guard let key = try? Curve25519.Signing.PublicKey(rawRepresentation: publicKeyData) else {
            return false
        }
        return key.isValidSignature(signature, for: payload)
    }
}

/// The crypto toggle. Development accepts unsigned payloads; production requires a
/// verified signature.
public enum PayloadSecurity: Sendable {
    /// DEVELOPMENT ONLY — accept a bare payload, or an envelope whose signature is
    /// NOT checked. Never ship this to production.
    case insecureDevelopment

    /// Production — require a signed envelope and verify it before trusting.
    case signed(any MurtiSignatureVerifier)
}
