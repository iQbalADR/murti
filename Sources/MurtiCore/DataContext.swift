import Foundation
import Observation

/// The token store threaded through a screen render — the glue of the data-context
/// lifecycle.
///
/// Nav params seed it; API responses merge in; `{{token}}` resolves against it at
/// render time. `@Observable` so dependent views re-resolve automatically with no
/// manual invalidation; `@MainActor` because it drives view state.
@MainActor
@Observable
public final class DataContext {
    private var storage: [String: MurtiValue]

    public init(_ seed: [String: MurtiValue] = [:]) {
        storage = seed
    }

    public subscript(_ key: String) -> MurtiValue? { storage[key] }

    /// A flat snapshot of the current values (used to seed a scoped child).
    public var snapshot: [String: MurtiValue] { storage }

    /// Merge values in (e.g. an API response landing under its request key).
    public func merge(_ values: [String: MurtiValue]) {
        for (key, value) in values { storage[key] = value }
    }

    /// Look up a dotted key path, e.g. `user.name`, walking nested objects.
    public func value(forKeyPath path: String) -> MurtiValue? {
        let parts = path.split(separator: ".").map(String.init)
        guard let first = parts.first else { return nil }
        var current = storage[first]
        for part in parts.dropFirst() {
            guard case .object(let object)? = current else { return nil }
            current = object[part]
        }
        return current
    }

    /// Interpolate `{{token}}`s against this context.
    public func resolve(_ template: String) -> String {
        TokenResolver.resolve(template) { self.value(forKeyPath: $0) }
    }
}
