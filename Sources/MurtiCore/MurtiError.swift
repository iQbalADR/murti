import Foundation

/// The single namespaced error type. Library/transport errors are never leaked
/// through the public API — they are mapped onto one of these.
public enum MurtiError: Error, Sendable, Equatable {
    case decode(String)             // structural decode failure (message)
    case schema(String)             // schema-conformance violation (pattern, required field)
    case unsupportedVersion(String) // schemaVersion major not supported
    case unknownType(String)        // no component registered for this type
    case unknownRequest(String)     // named request not allow-listed
    case unknownScreen(String)      // screen key not in the factory
    case bounds(String)             // a rendering bound was exceeded
    case network(status: Int?)      // transport failure (no library type leaked)
    case signatureInvalid           // authenticity check failed
    case decryptionFailed
    case tokenUnresolved(String)    // a required token had no value
}
