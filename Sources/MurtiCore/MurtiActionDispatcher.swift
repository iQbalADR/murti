import Foundation

/// Turns a decoded `MurtiActionSpec` into behavior (the Command pattern). Created
/// once with a network client and the host navigator, then passed to the engine.
@MainActor
public struct MurtiActionDispatcher {
    public let network: any MurtiNetworkClient
    public let navigator: MurtiNavigator

    public init(
        network: any MurtiNetworkClient = NoNetworkClient(),
        navigator: MurtiNavigator = MurtiNavigator()
    ) {
        self.network = network
        self.navigator = navigator
    }

    /// Build the command for an action type and run it. Chaining
    /// (`onSuccess`/`onError`) re-enters here; the chain is finite by construction
    /// and depth-bounded by validation.
    public func dispatch(_ spec: MurtiActionSpec, data: DataContext) async {
        await Self.command(for: spec.type).execute(spec: spec, data: data, dispatcher: self)
    }

    static func command(for type: ActionType) -> any MurtiCommand {
        switch type {
        case .navigate: NavigateCommand()
        case .api: APICommand()
        case .dismiss: DismissCommand()
        case .refresh: RefreshCommand()
        case .openURL: OpenURLCommand()
        }
    }

    /// A fire-and-forget dispatch closure for `MurtiRenderContext` — a tapped
    /// button hands off here and the async work runs on the main actor.
    public func sink(data: DataContext) -> @MainActor (MurtiActionSpec) -> Void {
        { spec in Task { await dispatch(spec, data: data) } }
    }
}
