import Foundation

/// An allow-listed request name. Extensible by design (like `Notification.Name`):
/// adopters add static members in their own module, so the framework never
/// hard-codes the app's endpoints. The JSON `request` string becomes one of these.
public struct NamedRequest: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: StringLiteralType) { self.rawValue = value }
}

/// The networking Strategy. `MurtiCore` has zero networking dependencies; the
/// adopter provides a client that owns the real base URL, auth, and pinning.
/// Library types are never leaked — the boundary is `Data` in, `MurtiError` out.
public protocol MurtiNetworkClient: Sendable {
    func perform(_ request: NamedRequest, params: [String: MurtiValue]) async throws -> Data
}

/// The default when no client is wired: every request is (correctly) unknown, so
/// an `api` action fails closed to its `onError`.
public struct NoNetworkClient: MurtiNetworkClient {
    public init() {}
    public func perform(_ request: NamedRequest, params: [String: MurtiValue]) async throws -> Data {
        throw MurtiError.unknownRequest(request.rawValue)
    }
}
