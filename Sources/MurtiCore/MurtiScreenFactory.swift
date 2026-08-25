import Foundation

/// The screen registry: a screen key → its JSON (Factory pattern). N screens =
/// N registrations, never a class per screen. Sources may be inline data, a
/// provider closure, or a bundled `<key>.json` file.
@MainActor
public final class MurtiScreenFactory {
    public typealias Provider = @Sendable () async throws -> Data

    private var providers: [String: Provider] = [:]
    private let bundle: Bundle?
    private let subdirectory: String?

    /// - Parameters:
    ///   - bundle: optional fallback bundle for keys with no explicit provider.
    ///   - subdirectory: optional subfolder inside the bundle (e.g. "Screens").
    public init(bundle: Bundle? = nil, subdirectory: String? = nil) {
        self.bundle = bundle
        self.subdirectory = subdirectory
    }

    @discardableResult
    public func register(_ key: String, data: Data) -> MurtiScreenFactory {
        providers[key] = { data }
        return self
    }

    @discardableResult
    public func register(_ key: String, provider: @escaping Provider) -> MurtiScreenFactory {
        providers[key] = provider
        return self
    }

    /// The JSON for a key, or `MurtiError.unknownScreen` if none resolves.
    public func data(for key: String) async throws -> Data {
        if let provider = providers[key] {
            return try await provider()
        }
        if let bundle,
           let url = bundle.url(forResource: key, withExtension: "json", subdirectory: subdirectory) {
            return try Data(contentsOf: url)
        }
        throw MurtiError.unknownScreen(key)
    }

    public var registeredKeys: [String] { providers.keys.sorted() }
}
