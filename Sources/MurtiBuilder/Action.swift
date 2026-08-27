import MurtiCore

/// Builds a `MurtiActionSpec` from the closed action set. Targets are named
/// references — a screen key, a named request, a named link — never a raw URL.
public struct Action {
    public let spec: MurtiActionSpec

    public static func navigate(_ screen: String, params: [String: MurtiValue]? = nil,
                                onSuccess: Action? = nil, onError: Action? = nil) -> Action {
        Action(spec: MurtiActionSpec(type: .navigate, screen: screen, params: params,
                                     onSuccess: onSuccess?.spec, onError: onError?.spec))
    }
    public static func api(_ request: String, params: [String: MurtiValue]? = nil,
                           onSuccess: Action? = nil, onError: Action? = nil) -> Action {
        Action(spec: MurtiActionSpec(type: .api, request: request, params: params,
                                     onSuccess: onSuccess?.spec, onError: onError?.spec))
    }
    public static var dismiss: Action { Action(spec: MurtiActionSpec(type: .dismiss)) }
    public static var refresh: Action { Action(spec: MurtiActionSpec(type: .refresh)) }
    public static func openURL(_ link: String) -> Action { Action(spec: MurtiActionSpec(type: .openURL, link: link)) }
}
