import CryptoKit
import Foundation

/// Filesystem-safe cache key = hex(SHA256("screenKey@version")).
func cacheKey(_ screenKey: String, _ version: String) -> String {
    let digest = SHA256.hash(data: Data("\(screenKey)@\(version)".utf8))
    return digest.map { String(format: "%02x", $0) }.joined()
}
