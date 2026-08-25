import Foundation

// The closed command set. Each maps one `ActionType` to native behavior.

struct NavigateCommand: MurtiCommand {
    func execute(spec: MurtiActionSpec, data: DataContext, dispatcher: MurtiActionDispatcher) async {
        guard let screen = spec.screen else { return }
        dispatcher.navigator.navigate(screen, spec.params ?? [:])
        if let next = spec.onSuccess { await dispatcher.dispatch(next, data: data) }
    }
}

struct DismissCommand: MurtiCommand {
    func execute(spec: MurtiActionSpec, data: DataContext, dispatcher: MurtiActionDispatcher) async {
        dispatcher.navigator.dismiss()
    }
}

struct RefreshCommand: MurtiCommand {
    func execute(spec: MurtiActionSpec, data: DataContext, dispatcher: MurtiActionDispatcher) async {
        dispatcher.navigator.refresh()
    }
}

struct OpenURLCommand: MurtiCommand {
    func execute(spec: MurtiActionSpec, data: DataContext, dispatcher: MurtiActionDispatcher) async {
        guard let link = spec.link else { return }
        dispatcher.navigator.openLink(link)
    }
}

/// The one command that reaches the network. On success the response merges into
/// the data context under the request's key, then `onSuccess` runs; any failure
/// runs `onError` — fail-closed.
struct APICommand: MurtiCommand {
    func execute(spec: MurtiActionSpec, data: DataContext, dispatcher: MurtiActionDispatcher) async {
        guard let request = spec.request else {
            await runError(spec, data: data, dispatcher: dispatcher)
            return
        }
        do {
            let bytes = try await dispatcher.network.perform(
                NamedRequest(rawValue: request),
                params: spec.params ?? [:]
            )
            if let value = try? JSONDecoder().decode(MurtiValue.self, from: bytes) {
                data.merge([request: value])
            }
            if let next = spec.onSuccess { await dispatcher.dispatch(next, data: data) }
        } catch {
            await runError(spec, data: data, dispatcher: dispatcher)
        }
    }

    private func runError(_ spec: MurtiActionSpec, data: DataContext, dispatcher: MurtiActionDispatcher) async {
        if let onError = spec.onError { await dispatcher.dispatch(onError, data: data) }
    }
}
