import Foundation
import SwiftUI
import MurtiCore

/// Records the most recent action a JSON-defined control dispatched, so the demo
/// can show that taps actually flow through the command layer.
@MainActor
@Observable
final class ActionLog {
    private(set) var last = "No action yet"
    func note(_ message: String) { last = message }
}

/// Owns the shared engine (wired with built-in components and a navigator that
/// reports effects into the `ActionLog`).
@MainActor
@Observable
final class GalleryModel {
    let actionLog: ActionLog
    let engine: MurtiEngine

    init() {
        let log = ActionLog()
        let navigator = MurtiNavigator(
            navigate: { screen, params in
                let suffix = params.isEmpty ? "" : " (" + params.keys.sorted().joined(separator: ", ") + ")"
                log.note("navigate → \(screen)\(suffix)")
            },
            dismiss: { log.note("dismiss") },
            refresh: { log.note("refresh") },
            openLink: { link in log.note("openURL → \(link)") }
        )
        self.actionLog = log
        self.engine = MurtiEngine(
            componentFactory: .withBuiltins,
            screenFactory: MurtiScreenFactory(),
            actionDispatcher: MurtiActionDispatcher(navigator: navigator)
        )
    }
}

struct GalleryRootView: View {
    @State private var model = GalleryModel()

    var body: some View {
        NavigationStack {
            List {
                Section("Examples") {
                    ForEach(GalleryExamples.all) { example in
                        NavigationLink {
                            ExampleDetailView(example: example, model: model)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(example.title)
                                Text(example.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section("Tools") {
                    NavigationLink("Hot reload (paste JSON)") {
                        HotReloadView(model: model)
                    }
                }
            }
            .navigationTitle("Murti Gallery")
        }
        .safeAreaInset(edge: .bottom) {
            ActionBanner(log: model.actionLog)
        }
    }
}

struct ActionBanner: View {
    let log: ActionLog

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "bolt.fill").foregroundStyle(.tint)
            Text("Last action:").fontWeight(.medium)
            Text(log.last).foregroundStyle(.secondary)
            Spacer()
        }
        .font(.footnote)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
}

struct ExampleDetailView: View {
    let example: GalleryExample
    let model: GalleryModel
    @State private var showSource = false

    var body: some View {
        Group {
            if showSource {
                ScrollView {
                    Text(example.json)
                        .font(.system(.footnote, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            } else {
                ScrollView {
                    MurtiScreen(.inline(Data(example.json.utf8)), engine: model.engine, seed: example.seed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
        .navigationTitle(example.title)
        .toolbar {
            Button(showSource ? "Preview" : "JSON") { showSource.toggle() }
        }
    }
}

struct HotReloadView: View {
    let model: GalleryModel
    @State private var json: String = GalleryExamples.all.first?.json ?? "{}"

    var body: some View {
        VStack(spacing: 0) {
            TextEditor(text: $json)
                .font(.system(.footnote, design: .monospaced))
                .frame(maxHeight: 280)
                .overlay(Rectangle().stroke(.quaternary))
            Divider()
            ScrollView {
                // MurtiScreen re-renders whenever the JSON (its source identity) changes.
                MurtiScreen(.inline(Data(json.utf8)), engine: model.engine)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
        .navigationTitle("Hot reload")
    }
}
