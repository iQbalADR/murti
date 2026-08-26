import Foundation

/// The version index: which version of each screen is current. Fetched as a
/// signed payload; `sequence` is monotonic so an older manifest is rejected.
public struct Manifest: Sendable, Hashable, Codable {
    public let sequence: Int
    public let screens: [String: String]
    public init(sequence: Int, screens: [String: String]) {
        self.sequence = sequence
        self.screens = screens
    }
}
