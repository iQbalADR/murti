import CryptoKit
import Foundation
import Testing
@testable import MurtiCore

@MainActor
@Suite("refreshManifest")
struct MurtiManifestTests {
    let key = Curve25519.Signing.PrivateKey()
    var verifier: Ed25519Verifier { try! Ed25519Verifier(publicKey: key.publicKey.rawRepresentation) }
    func manifestEnvelope(_ seq: Int, _ screens: [String: String]) -> Data {
        let payload = try! JSONEncoder().encode(Manifest(sequence: seq, screens: screens))
        let sig = try! key.signature(for: payload)
        return try! JSONEncoder().encode(MurtiEnvelope(schemaVersion: "1.0", alg: "ed25519", payload: payload, signature: sig))
    }
    func engine(_ loader: @escaping @Sendable () async throws -> Data) -> MurtiEngine {
        MurtiEngine(componentFactory: .withBuiltins, screenFactory: MurtiScreenFactory(),
                    security: .signed(verifier),
                    cache: MurtiCache(store: MemoryCacheStore(), cipher: PassthroughCipher()),
                    manifestLoader: loader)
    }

    @Test func refreshAppliesSignedManifest() async throws {
        let e = engine { await self.manifestEnvelope(7, ["home": "v7"]) }
        try await e.refreshManifest()
        #expect(e.coordinator?.version(for: "home") == "v7")
    }
    @Test func forgedManifestRejected() async {
        let attacker = Curve25519.Signing.PrivateKey()
        let e = engine {
            let payload = try! JSONEncoder().encode(Manifest(sequence: 9, screens: ["home": "v9"]))
            let sig = try! attacker.signature(for: payload)
            return try! JSONEncoder().encode(MurtiEnvelope(schemaVersion: "1.0", alg: "ed25519", payload: payload, signature: sig))
        }
        await #expect(throws: (any Error).self) { try await e.refreshManifest() }
    }
}
