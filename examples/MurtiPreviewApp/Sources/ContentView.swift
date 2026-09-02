import SwiftUI
import MurtiCore

/// Holds the engine (built-ins + a `url`/placeholder-aware `image`) and loads the
/// bundled `Screen.json` to render. Replace that file with your Figma export.
@MainActor
@Observable
final class PreviewModel {
    let engine: MurtiEngine

    init() {
        let navigator = MurtiNavigator(
            navigate: { screen, _ in print("navigate → \(screen)") },
            dismiss: { print("dismiss") },
            refresh: { print("refresh") },
            openLink: { link in print("openURL → \(link)") }
        )
        // Relaxed bounds so an embedded-image export (base64 far exceeds the
        // production 4096-char string cap) still loads in this preview harness.
        let bounds = MurtiBounds(
            maxDepth: 128,
            maxNodes: 100_000,
            maxStringLength: 64_000_000,
            maxProps: 512,
            maxChildren: 2048,
            maxArrayItems: 8192
        )
        engine = MurtiEngine(
            componentFactory: .preview,
            screenFactory: MurtiScreenFactory(),
            actionDispatcher: MurtiActionDispatcher(navigator: navigator),
            validator: MurtiSchemaValidator(bounds: bounds)
        )
    }

    var json: Data {
        if let url = Bundle.main.url(forResource: "Screen", withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            return data
        }
        return Data(#"{"schemaVersion":"1.0","screen":{"key":"placeholder","root":{"type":"text","props":{"value":"Add Resources/Screen.json"}}}}"#.utf8)
    }
}

struct ContentView: View {
    @State private var model = PreviewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                MurtiScreen(.inline(model.json), engine: model.engine)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .navigationTitle("Murti Preview")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
