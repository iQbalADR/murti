import Foundation

/// File-backed cache with OS Data Protection. Filenames are already hashed by the
/// caller (`cacheKey`); each key is validated to be a single safe path component
/// (no `/`, `.`, or `..`) before use.
public actor FileCacheStore: MurtiCacheStore {
    private let directory: URL
    public init(directory: URL = FileCacheStore.defaultDirectory) { self.directory = directory }

    public func data(for key: String) -> Data? {
        guard let url = url(for: key) else { return nil }
        return try? Data(contentsOf: url)
    }
    public func store(_ data: Data, for key: String) {
        guard let url = url(for: key) else { return }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        #if canImport(UIKit)
        try? data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        #else
        try? data.write(to: url, options: .atomic)
        #endif
    }
    public func remove(_ key: String) {
        guard let url = url(for: key) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    /// Map a key to a URL inside `directory`, rejecting empty keys, path separators,
    /// and the `.`/`..` segments so a caller cannot escape the cache directory.
    private func url(for key: String) -> URL? {
        guard !key.isEmpty, !key.contains("/"), key != "..", key != "." else { return nil }
        return directory.appending(path: key)
    }

    public static var defaultDirectory: URL {
        (try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true))?
            .appending(path: "Murti") ?? URL.temporaryDirectory.appending(path: "Murti")
    }
}
