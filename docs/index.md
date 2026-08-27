# Murti

A SwiftUI-native **server-driven UI** framework — render native screens from JSON,
navigate and call APIs declaratively, extend with any third-party component, with
fintech-grade validation, signing, and secure caching.

The server describes *what* a screen is; the client owns *how* it renders,
navigates, and talks to the network. Ship layout changes without an App Store
release. Deliberately **SwiftUI-only** — a strength, not a limitation.

[Get the code on GitHub](https://github.com/iQbalADR/murti){ .md-button .md-button--primary }

## Install

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/iQbalADR/murti.git", branch: "main"),
]
// add "MurtiCore" to your target's dependencies
```

## 60-second quickstart

```swift
import SwiftUI
import MurtiCore

// Create the engine, giving it the component/screen factories and the action dispatcher.
let engine = MurtiEngine(
    componentFactory: .withBuiltins,                 // text, image, vstack, hstack, button, card
    screenFactory: MurtiScreenFactory().register("home", data: homeJSON),
    actionDispatcher: MurtiActionDispatcher(network: MyNetworkClient(), navigator: MurtiNavigator())
)

// MurtiScreen loads the JSON registered for "home" and renders it.
struct RootView: View {
    var body: some View {
        NavigationStack { MurtiScreen(.key("home"), engine: engine) }
    }
}
```

## Reference

- [Payload schema & validation](schema.md) — the authoritative JSON Schema, the
  `schemaVersion` policy, bounds, valid/invalid fixtures, and the signed manifest.
- [Networking adapters](networking.md) — the `MurtiNetworkClient` port plus
  ready-to-copy Alamofire / Moya / URLSession adapters.

## Why Murti

- **Extend by data or by one file** — a new screen is JSON + one factory entry; a
  new component is one `MurtiComponent`; a new action is one command; wrapping a
  library is one self-registering component (or a one-line closure).
- **Fintech-grade security** — TLS-pinning hooks, Ed25519 signature verification
  (re-verified on every load, including from cache), bounded validation, a closed
  action vocabulary, and an optionally-encrypted at-rest cache.
- **Zero third-party dependencies** in `MurtiCore`; optional adapters bring their
  own.
