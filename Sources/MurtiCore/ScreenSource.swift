import Foundation

/// Where a screen's JSON comes from.
public enum ScreenSource: Sendable, Hashable {
    case key(String)      // a `MurtiScreenFactory` entry
    case named(String)    // a remote, allow-listed source (host-resolved) — no raw URLs
    case inline(Data)     // previews / tests / hot-reload

    /// Stable identity string for SwiftUI `.id(...)`, so state never leaks between
    /// screens and a source change forces a fresh load.
    public var identity: String {
        switch self {
        case .key(let key): "key:\(key)"
        case .named(let name): "named:\(name)"
        case .inline(let data): "inline:\(data.count):\(data.hashValue)"
        }
    }
}

/// The load lifecycle for one screen. Fail-closed: never a blank screen or crash.
public enum LoadState: Sendable, Equatable {
    case loading
    case loaded(MurtiNode)
    case failed(MurtiError)
}
