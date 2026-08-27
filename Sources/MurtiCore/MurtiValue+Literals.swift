import Foundation

extension MurtiValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) { self = .string(value) }
}
extension MurtiValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) { self = .number(Double(value)) }
}
extension MurtiValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) { self = .number(value) }
}
extension MurtiValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) { self = .bool(value) }
}
extension MurtiValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: MurtiValue...) { self = .array(elements) }
}
extension MurtiValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, MurtiValue)...) {
        self = .object(Dictionary(uniqueKeysWithValues: elements))
    }
}
