import Foundation
import MurtiCore

/// Generates MurtiBuilder DSL source from a decoded node tree — the inverse of the
/// DSL. The output compiles against this module and rebuilds an equivalent tree.
///
/// A node is written with its typed initializer (`Text`, `VStack`, `Button`, …)
/// when its props fit that initializer exactly; anything else falls back to the
/// open-vocabulary `component("type", [props]) { … }` so no props are lost. Node
/// ids aren't emitted (the DSL doesn't set them), matching JSON export. An action
/// on a non-button can't be expressed in the DSL, so it's omitted with a note.
public enum DSLExport {
    public static func source(for payload: MurtiPayload) -> String {
        source(forScreen: payload.screen.key, root: payload.screen.root, schemaVersion: payload.schemaVersion)
    }

    public static func source(forScreen key: String, root: MurtiNode, schemaVersion: String = "1.0") -> String {
        var head = "Screen(\(string(key))"
        if schemaVersion != "1.0" { head += ", schemaVersion: \(string(schemaVersion))" }
        head += ") {"
        return "\(head)\n\(node(root, level: 1))\n}"
    }

    /// The source for a single node, as a standalone expression.
    public static func source(for node: MurtiNode) -> String { self.node(node, level: 0) }

    // MARK: - Node dispatch

    private static func node(_ n: MurtiNode, level: Int) -> String {
        let pad = indent(level)
        switch n.type {
        case "text" where fitsText(n): return pad + textExpr(n)
        case "image" where fitsImage(n): return pad + imageExpr(n)
        case "button" where fitsButton(n): return pad + buttonExpr(n)
        case "vstack" where fitsStack(n, vertical: true): return container(n, level: level, head: stackHead(n, "VStack"))
        case "hstack" where fitsStack(n, vertical: false): return container(n, level: level, head: stackHead(n, "HStack"))
        case "card" where fitsCard(n): return container(n, level: level, head: cardHead(n))
        default: return componentExpr(n, level: level)
        }
    }

    private static func container(_ n: MurtiNode, level: Int, head: String) -> String {
        let pad = indent(level)
        if n.children.isEmpty { return "\(pad)\(head) {\n\(pad)}" }
        let kids = n.children.map { node($0, level: level + 1) }.joined(separator: "\n")
        return "\(pad)\(head) {\n\(kids)\n\(pad)}"
    }

    private static func componentExpr(_ n: MurtiNode, level: Int) -> String {
        let pad = indent(level)
        var head = "component(\(string(n.type))"
        if !n.props.isEmpty { head += ", \(propsLiteral(n.props))" }
        head += ")"

        let body: String
        if n.children.isEmpty {
            body = "\(pad)\(head)"
        } else {
            let kids = n.children.map { node($0, level: level + 1) }.joined(separator: "\n")
            body = "\(pad)\(head) {\n\(kids)\n\(pad)}"
        }
        if n.action != nil {
            return "\(pad)// note: an action on \"\(n.type)\" isn't expressible in the DSL and was omitted\n\(body)"
        }
        return body
    }

    // MARK: - text

    private static func fitsText(_ n: MurtiNode) -> Bool {
        guard n.children.isEmpty, n.action == nil else { return false }
        guard Set(n.props.keys).isSubset(of: ["value", "style", "a11yLabel", "a11yId"]) else { return false }
        guard n.props["value"]?.stringValue != nil else { return false }
        if let style = n.props["style"] {
            guard let raw = style.stringValue, ["title", "headline", "caption", "body"].contains(raw) else { return false }
        }
        if let a = n.props["a11yLabel"], a.stringValue == nil { return false }
        if let a = n.props["a11yId"], a.stringValue == nil { return false }
        return true
    }

    private static func textExpr(_ n: MurtiNode) -> String {
        var args = [string(n.props["value"]!.stringValue!)]
        if let raw = n.props["style"]?.stringValue { args.append("style: .\(raw)") }
        if let v = n.props["a11yLabel"]?.stringValue { args.append("a11yLabel: \(string(v))") }
        if let v = n.props["a11yId"]?.stringValue { args.append("a11yId: \(string(v))") }
        return "Text(" + args.joined(separator: ", ") + ")"
    }

    // MARK: - vstack / hstack

    private static func fitsStack(_ n: MurtiNode, vertical: Bool) -> Bool {
        guard n.action == nil else { return false }
        guard Set(n.props.keys).isSubset(of: ["spacing", "alignment"]) else { return false }
        if let sp = n.props["spacing"], sp.doubleValue == nil { return false }
        if let al = n.props["alignment"] {
            guard let raw = al.stringValue else { return false }
            let valid = vertical ? ["leading", "center", "trailing"] : ["top", "center", "bottom"]
            guard valid.contains(raw) else { return false }
        }
        return true
    }

    private static func stackHead(_ n: MurtiNode, _ name: String) -> String {
        var args: [String] = []
        if let sp = n.props["spacing"]?.doubleValue { args.append("spacing: \(numberLiteral(sp))") }
        if let al = n.props["alignment"]?.stringValue { args.append("alignment: .\(al)") }
        return args.isEmpty ? name : "\(name)(" + args.joined(separator: ", ") + ")"
    }

    // MARK: - button

    private static func fitsButton(_ n: MurtiNode) -> Bool {
        guard n.children.isEmpty else { return false }
        guard Set(n.props.keys).isSubset(of: ["title", "a11yId"]) else { return false }
        guard n.props["title"]?.stringValue != nil else { return false }
        if let a = n.props["a11yId"], a.stringValue == nil { return false }
        return true
    }

    private static func buttonExpr(_ n: MurtiNode) -> String {
        var args = [string(n.props["title"]!.stringValue!)]
        if let action = n.action { args.append("action: \(actionExpr(action))") }
        if let v = n.props["a11yId"]?.stringValue { args.append("a11yId: \(string(v))") }
        return "Button(" + args.joined(separator: ", ") + ")"
    }

    // MARK: - image

    private static func fitsImage(_ n: MurtiNode) -> Bool {
        guard n.children.isEmpty, n.action == nil else { return false }
        let ks = Set(n.props.keys)
        if ks == ["systemName"] { return n.props["systemName"]?.stringValue != nil }
        guard ks.isSubset(of: ["name", "contentMode"]), n.props["name"]?.stringValue != nil else { return false }
        if let cm = n.props["contentMode"], cm.stringValue == nil { return false }
        return true
    }

    private static func imageExpr(_ n: MurtiNode) -> String {
        if Set(n.props.keys) == ["systemName"], let sys = n.props["systemName"]?.stringValue {
            return "Image(systemName: \(string(sys)))"
        }
        var args = ["name: \(string(n.props["name"]!.stringValue!))"]
        if let cm = n.props["contentMode"]?.stringValue { args.append("contentMode: \(string(cm))") }
        return "Image(" + args.joined(separator: ", ") + ")"
    }

    // MARK: - card

    private static func fitsCard(_ n: MurtiNode) -> Bool {
        guard n.action == nil else { return false }
        guard Set(n.props.keys).isSubset(of: ["padding"]) else { return false }
        if let p = n.props["padding"], p.doubleValue == nil { return false }
        return true
    }

    private static func cardHead(_ n: MurtiNode) -> String {
        if let p = n.props["padding"]?.doubleValue { return "Card(padding: \(numberLiteral(p)))" }
        return "Card"
    }

    // MARK: - actions

    private static func actionExpr(_ a: MurtiActionSpec) -> String {
        switch a.type {
        case .navigate: return chainedAction("navigate", target: a.screen, a)
        case .api: return chainedAction("api", target: a.request, a)
        case .dismiss: return ".dismiss"
        case .refresh: return ".refresh"
        case .openURL: return ".openURL(\(string(a.link ?? "")))"
        }
    }

    private static func chainedAction(_ verb: String, target: String?, _ a: MurtiActionSpec) -> String {
        var args = [string(target ?? "")]
        if let params = a.params, !params.isEmpty { args.append("params: \(propsLiteral(params))") }
        if let ok = a.onSuccess { args.append("onSuccess: \(actionExpr(ok))") }
        if let err = a.onError { args.append("onError: \(actionExpr(err))") }
        return ".\(verb)(" + args.joined(separator: ", ") + ")"
    }

    // MARK: - Literals

    private static func propsLiteral(_ props: [String: MurtiValue]) -> String {
        let pairs = props.keys.sorted().map { "\(string($0)): \(valueLiteral(props[$0]!))" }
        return "[" + pairs.joined(separator: ", ") + "]"
    }

    private static func valueLiteral(_ v: MurtiValue) -> String {
        switch v {
        case .string(let s): return string(s)
        case .number(let n): return numberLiteral(n)
        case .bool(let b): return b ? "true" : "false"
        case .null: return ".null"
        case .array(let arr):
            return arr.isEmpty ? "[]" : "[" + arr.map(valueLiteral).joined(separator: ", ") + "]"
        case .object(let obj):
            if obj.isEmpty { return "[:]" }
            let pairs = obj.keys.sorted().map { "\(string($0)): \(valueLiteral(obj[$0]!))" }
            return "[" + pairs.joined(separator: ", ") + "]"
        }
    }

    private static func numberLiteral(_ v: Double) -> String {
        if v.rounded() == v && abs(v) < 1e15 { return String(Int(v)) }
        return String(v)
    }

    private static func string(_ s: String) -> String {
        var out = "\""
        for ch in s {
            switch ch {
            case "\\": out += "\\\\"
            case "\"": out += "\\\""
            case "\n": out += "\\n"
            case "\t": out += "\\t"
            case "\r": out += "\\r"
            default: out.append(ch)
            }
        }
        out += "\""
        return out
    }

    private static func indent(_ level: Int) -> String { String(repeating: "    ", count: level) }
}
