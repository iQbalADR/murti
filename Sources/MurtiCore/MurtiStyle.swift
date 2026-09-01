import SwiftUI

// The bounded style layer: a small, closed set of visual props the built-in
// components read, on top of their structural props. A color is a hex string, a
// font weight is a known name, a radius/size is a number — validated at render
// time, and simply ignored when unrecognized (render-what-you-can). This is not
// arbitrary CSS: the value space stays closed.

/// Straight RGBA components in 0...1, parsed from a hex string. Kept separate from
/// `Color` so the parsing is unit-testable without a SwiftUI environment.
struct MurtiRGBA: Equatable {
    let red, green, blue, alpha: Double
}

/// Parse `#RGB`, `#RRGGBB`, or `#RRGGBBAA` (the leading `#` is optional). Returns
/// `nil` for anything else, so an unrecognized value leaves styling untouched.
func murtiParseHexColor(_ hex: String) -> MurtiRGBA? {
    var s = hex.trimmingCharacters(in: .whitespaces)
    if s.hasPrefix("#") { s.removeFirst() }
    guard !s.isEmpty, s.allSatisfy(\.isHexDigit) else { return nil }

    func channel(_ value: UInt64, shift: UInt64) -> Double { Double((value >> shift) & 0xFF) / 255 }

    switch s.count {
    case 3:
        let expanded = s.map { "\($0)\($0)" }.joined()
        guard let n = UInt64(expanded, radix: 16) else { return nil }
        return MurtiRGBA(red: channel(n, shift: 16), green: channel(n, shift: 8), blue: channel(n, shift: 0), alpha: 1)
    case 6:
        guard let n = UInt64(s, radix: 16) else { return nil }
        return MurtiRGBA(red: channel(n, shift: 16), green: channel(n, shift: 8), blue: channel(n, shift: 0), alpha: 1)
    case 8:
        guard let n = UInt64(s, radix: 16) else { return nil }
        return MurtiRGBA(red: channel(n, shift: 24), green: channel(n, shift: 16), blue: channel(n, shift: 8), alpha: channel(n, shift: 0))
    default:
        return nil
    }
}

extension Color {
    /// A color from a Murti hex string, or `nil` when the string isn't a hex color.
    init?(murtiHex hex: String) {
        guard let c = murtiParseHexColor(hex) else { return nil }
        self = Color(.sRGB, red: c.red, green: c.green, blue: c.blue, opacity: c.alpha)
    }
}

/// A known font weight name, or `nil`.
func murtiFontWeight(_ name: String) -> Font.Weight? {
    switch name {
    case "ultralight": .ultraLight
    case "thin": .thin
    case "light": .light
    case "regular": .regular
    case "medium": .medium
    case "semibold": .semibold
    case "bold": .bold
    case "heavy": .heavy
    case "black": .black
    default: nil
    }
}

extension View {
    /// Apply the shared container style props (`padding`, `background`,
    /// `cornerRadius`, `foreground`) from a node. Each is applied only when present,
    /// so a node without them renders exactly as before.
    func murtiStyle(_ node: MurtiNode) -> some View {
        modifier(MurtiStyleModifier(node: node))
    }
}

private struct MurtiStyleModifier: ViewModifier {
    let node: MurtiNode

    func body(content: Content) -> some View {
        var view = AnyView(content)
        if let padding = node.value("padding")?.doubleValue {
            view = AnyView(view.padding(CGFloat(padding)))
        }
        if let background = Color(murtiHex: node.string("background")) {
            view = AnyView(view.background(background))
        }
        if let radius = node.value("cornerRadius")?.doubleValue {
            view = AnyView(view.clipShape(RoundedRectangle(cornerRadius: CGFloat(radius))))
        }
        if let foreground = Color(murtiHex: node.string("foreground")) {
            view = AnyView(view.foregroundStyle(foreground))
        }
        return view
    }
}

/// Sets the foreground color from a hex prop, leaving it untouched when absent or
/// unrecognized. Used by `text` (its `color` prop) and `card` (its `foreground`).
struct MurtiForegroundColor: ViewModifier {
    let hex: String
    func body(content: Content) -> some View {
        if let color = Color(murtiHex: hex) {
            content.foregroundStyle(color)
        } else {
            content
        }
    }
}
