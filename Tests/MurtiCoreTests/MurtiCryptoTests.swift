import CryptoKit
import Foundation
import Testing
@testable import MurtiCore

@MainActor
@Suite("Signature verification & PayloadSecurity")
struct MurtiCryptoTests {
    private let payloadJSON = Data(#"{"schemaVersion":"1.0","screen":{"key":"s","root":{"type":"text"}}}"#.utf8)

    private func engine(_ security: PayloadSecurity) -> MurtiEngine {
        MurtiEngine(componentFactory: .withBuiltins, screenFactory: MurtiScreenFactory(), security: security)
    }

    private func envelope(payload: Data, signature: Data) throws -> Data {
        try JSONEncoder().encode(
            MurtiEnvelope(schemaVersion: "1.0", alg: "ed25519", payload: payload, signature: signature)
        )
    }

    // MARK: - Verifier unit

    @Test func acceptsValidSignature() throws {
        let key = Curve25519.Signing.PrivateKey()
        let verifier = try Ed25519Verifier(publicKey: key.publicKey.rawRepresentation)
        let signature = try key.signature(for: payloadJSON)
        #expect(verifier.verify(payload: payloadJSON, signature: signature))
    }

    @Test func rejectsTamperedPayload() throws {
        let key = Curve25519.Signing.PrivateKey()
        let verifier = try Ed25519Verifier(publicKey: key.publicKey.rawRepresentation)
        let signature = try key.signature(for: payloadJSON)
        #expect(!verifier.verify(payload: payloadJSON + Data(" ".utf8), signature: signature))
    }

    @Test func rejectsSignatureFromWrongKey() throws {
        let signer = Curve25519.Signing.PrivateKey()
        let attacker = Curve25519.Signing.PrivateKey()
        let verifier = try Ed25519Verifier(publicKey: attacker.publicKey.rawRepresentation)
        let signature = try signer.signature(for: payloadJSON)
        #expect(!verifier.verify(payload: payloadJSON, signature: signature))
    }

    // MARK: - Engine, .signed policy

    @Test func signedPolicyLoadsValidEnvelope() async throws {
        let key = Curve25519.Signing.PrivateKey()
        let verifier = try Ed25519Verifier(publicKey: key.publicKey.rawRepresentation)
        let signature = try key.signature(for: payloadJSON)
        let data = try envelope(payload: payloadJSON, signature: signature)
        guard case .loaded(let root) = await engine(.signed(verifier)).load(.inline(data)) else {
            Issue.record("expected .loaded"); return
        }
        #expect(root.type == "text")
    }

    @Test func signedPolicyRejectsForgedPayload() async throws {
        let key = Curve25519.Signing.PrivateKey()
        let verifier = try Ed25519Verifier(publicKey: key.publicKey.rawRepresentation)
        // Sign the real payload, then ship a different one under that signature.
        let signature = try key.signature(for: payloadJSON)
        let forged = Data(#"{"schemaVersion":"1.0","screen":{"key":"s","root":{"type":"button","props":{"title":"HACKED"}}}}"#.utf8)
        let data = try envelope(payload: forged, signature: signature)
        #expect(await engine(.signed(verifier)).load(.inline(data)) == .failed(.signatureInvalid))
    }

    @Test func signedPolicyRejectsUnsignedPayload() async throws {
        let key = Curve25519.Signing.PrivateKey()
        let verifier = try Ed25519Verifier(publicKey: key.publicKey.rawRepresentation)
        #expect(await engine(.signed(verifier)).load(.inline(payloadJSON)) == .failed(.signatureInvalid))
    }

    // MARK: - Engine, .insecureDevelopment policy (the dev toggle)

    @Test func developmentAcceptsBarePayload() async {
        guard case .loaded = await engine(.insecureDevelopment).load(.inline(payloadJSON)) else {
            Issue.record("expected .loaded"); return
        }
    }

    @Test func developmentAcceptsEnvelopeWithoutVerifying() async throws {
        let data = try envelope(payload: payloadJSON, signature: Data("bogus".utf8))
        guard case .loaded = await engine(.insecureDevelopment).load(.inline(data)) else {
            Issue.record("expected .loaded"); return
        }
    }
}
