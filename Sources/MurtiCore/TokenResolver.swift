import Foundation

/// Resolves `{{token}}` interpolation in a template string.
///
/// Pure and non-isolated: it takes a `lookup` closure rather than the data store
/// directly, so it is trivially testable and free of any actor requirement.
/// Missing tokens resolve to an empty string (fail-soft, never a crash).
enum TokenResolver {
    static func resolve(_ template: String, lookup: (String) -> MurtiValue?) -> String {
        guard template.contains("{{") else { return template }

        var result = ""
        var rest = Substring(template)

        while let open = rest.range(of: "{{") {
            result += rest[..<open.lowerBound]
            let afterOpen = rest[open.upperBound...]
            guard let close = afterOpen.range(of: "}}") else {
                // Unterminated token: emit the remainder literally.
                result += rest[open.lowerBound...]
                return result
            }
            let key = afterOpen[..<close.lowerBound].trimmingCharacters(in: .whitespaces)
            result += lookup(key)?.displayString ?? ""
            rest = afterOpen[close.upperBound...]
        }

        result += rest
        return result
    }
}
