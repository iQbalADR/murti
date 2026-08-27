# Authoring screens

Murti renders screens from JSON. `MurtiBuilder` is a Swift DSL that produces that
JSON, so you can write screens in typed Swift instead of by hand, and `MurtiGen`
turns authored screens into validated JSON files at build time.

Both run on Apple platforms and depend on `MurtiCore`.

## The DSL

```swift
import MurtiBuilder

let dashboard = Screen("dashboard") {
    VStack(spacing: 12, alignment: .leading) {
        Text("Hello, {{user.name}}", style: .title)
        Button("View details",
               action: .navigate("productDetail", params: ["productId": "abc123"]))
        Button("Load balance",
               action: .api("getAccountBalance", onSuccess: .navigate("balanceDetail")))
    }
}

let json = try dashboard.validated().jsonData()
```

`{{user.name}}` stays in the output verbatim; the app resolves tokens at render
time. `validated()` runs the schema validator and throws if the screen is invalid;
`jsonData()` encodes the payload (with sorted keys, so output is stable).

### Built-in components

`Text`, `Image`, `VStack`, `HStack`, `Button`, and `Card` cover the built-in
component set. Containers take a child closure; the closure supports `if` and
`for`:

```swift
VStack(spacing: 8) {
    if showHeader { Text("Recent", style: .headline) }
    for item in items { Text(item.title) }
}
```

### Any other component

The built-ins mirror the renderer's built-in set, but the registry is open. Use
`component(_:_:)` to author a third-party or custom type by its `type` string:

```swift
component("lottie", ["name": "success_check", "loop": false])
component("rating", ["stars": 4])
```

### Actions

`Button` takes an `Action`: `.navigate(_:params:onSuccess:onError:)`,
`.api(_:params:onSuccess:onError:)`, `.dismiss`, `.refresh`, or `.openURL(_:)`.
Targets are named references (a screen key, a named request, a named link), never
a raw URL.

### A note on names

`Text`, `VStack`, `Button`, and `Image` share names with SwiftUI. Write
screen-authoring files that `import MurtiBuilder` but not `SwiftUI`; if a file
needs both, qualify the DSL type as `MurtiBuilder.Text`.

## Build-time generation

`MurtiGen` writes each authored screen to `<key>.json`, validating every screen
first so a bad bundle never ships. Author screens in
[`Sources/MurtiGen/main.swift`](https://github.com/iQbalADR/murti/blob/main/Sources/MurtiGen/main.swift)
(loop over data for lists), then run:

```
swift run MurtiGen Generated
```

Serve the resulting JSON from any backend or CDN as opaque bytes. The structure is
fixed at generation time; dynamic values stay at runtime through `{{token}}`s and
named API requests. To ship signed, production-ready payloads, wrap the output in
a signed envelope (see the security model) as part of your build.
