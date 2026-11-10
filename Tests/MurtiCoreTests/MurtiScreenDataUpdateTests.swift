#if canImport(AppKit)
import AppKit
import SwiftUI
import Testing
@testable import MurtiCore

/// Hosts a `MurtiScreen` in a window and checks that it renders again when an
/// `api` action merges a response into its data context.
@MainActor
@Suite("MurtiScreen data updates")
struct MurtiScreenDataUpdateTests {

    /// Collects what the probe component resolved on each render.
    @MainActor
    final class Probe {
        var resolved: [String] = []
    }

    struct ProfileNetwork: MurtiNetworkClient {
        func perform(_ request: NamedRequest, params: [String: MurtiValue]) async throws -> Data {
            Data(#"{ "name": "Ada" }"#.utf8)
        }
    }

    @Test func rerendersWhenAnAPIResponseMerges() async throws {
        let probe = Probe()
        // The probe records its token on every render and fires the `api` action
        // once it appears.
        let factory = MurtiComponentFactory.withBuiltins.register("probe") { _, context in
            let name = context.resolve("{{profile.name}}")
            let _ = probe.resolved.append(name)
            Text(name)
                .onAppear { context.dispatch(MurtiActionSpec(type: .api, request: "profile")) }
        }
        let engine = MurtiEngine(
            componentFactory: factory,
            screenFactory: MurtiScreenFactory(),
            actionDispatcher: MurtiActionDispatcher(network: ProfileNetwork())
        )
        let json = #"{ "schemaVersion": "1.0", "screen": { "key": "probe", "root": { "type": "probe" } } }"#

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 200),
            styleMask: [.borderless], backing: .buffered, defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: MurtiScreen(.inline(Data(json.utf8)), engine: engine))
        window.orderFrontRegardless()
        defer { window.close() }

        for _ in 0..<100 where !probe.resolved.contains("Ada") {
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        #expect(probe.resolved.first != "Ada")
        #expect(probe.resolved.contains("Ada"))
    }
}
#endif
