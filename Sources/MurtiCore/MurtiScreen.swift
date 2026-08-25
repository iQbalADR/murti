import SwiftUI

/// One generic screen, driven entirely by data. N screens = N JSON sources, never
/// a class per screen. It loads its source, renders the tree, and wires action
/// dispatch — fail-closed at every step.
///
/// `.id(source.identity)` gives each source stable identity so SwiftUI never
/// leaks state between screens (and a source change forces a fresh load).
@MainActor
public struct MurtiScreen: View {
    private let source: ScreenSource
    private let explicitEngine: MurtiEngine?
    @Environment(\.murti) private var environmentEngine
    @State private var state: LoadState = .loading
    @State private var data: DataContext

    /// - Parameters:
    ///   - source: where the screen JSON comes from.
    ///   - engine: the engine (or inject one via `.murtiEngine(_:)`).
    ///   - seed: initial data context (e.g. navigation params).
    public init(_ source: ScreenSource, engine: MurtiEngine? = nil, seed: [String: MurtiValue] = [:]) {
        self.source = source
        self.explicitEngine = engine
        _data = State(initialValue: DataContext(seed))
    }

    public var body: some View {
        resolved
            .id(source.identity)
            .task(id: source.identity) { await reload() }
    }

    private func reload() async {
        guard let engine = explicitEngine ?? environmentEngine else {
            state = .failed(.decode("MurtiScreen has no engine — pass `engine:` or use `.murtiEngine(_:)`."))
            return
        }
        state = .loading
        state = await engine.load(source)
    }

    @ViewBuilder
    private var resolved: some View {
        switch state {
        case .loading:
            ProgressView()
        case .loaded(let root):
            if let engine = explicitEngine ?? environmentEngine {
                engine.renderer.render(root, data: data, dispatch: engine.actionDispatcher.sink(data: data))
            } else {
                MurtiErrorView(error: .decode("MurtiScreen has no engine."))
            }
        case .failed(let error):
            MurtiErrorView(error: error)
        }
    }
}

// MARK: - Engine injection

private struct MurtiEngineKey: EnvironmentKey {
    static let defaultValue: MurtiEngine? = nil
}

public extension EnvironmentValues {
    var murti: MurtiEngine? {
        get { self[MurtiEngineKey.self] }
        set { self[MurtiEngineKey.self] = newValue }
    }
}

public extension View {
    /// Inject the engine so nested `MurtiScreen`s (e.g. navigation destinations)
    /// pick it up automatically.
    func murtiEngine(_ engine: MurtiEngine) -> some View {
        environment(\.murti, engine)
    }
}

// MARK: - Fail-closed error surface

struct MurtiErrorView: View {
    let error: MurtiError

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.secondary)
            Text("Couldn't load this screen")
                .font(.headline)
            #if DEBUG
            Text(String(describing: error))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            #endif
        }
        .padding()
    }
}
