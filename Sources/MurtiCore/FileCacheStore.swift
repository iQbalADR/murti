import Foundation

/// File-backed cache with OS Data Protection. Filenames are already hashed by the
/// caller (`cacheKey`), so they are written verbatim.
public actor FileCacheStore: MurtiCacheStore {
    private let directory: URL
    public init(directory: URL = FileCacheStore.defaultDirectory) { self.directory = directory }

    public func data(for key: String) -> Data? {
        try? Data(contentsOf: directory.appending(path: key))
    }
    public func store(_ data: Data, for key: String) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        #if canImport(UIKit)
        try? data.write(to: directory.appending(path: key), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        #else
        try? data.write(to: directory.appending(path: key), options: .atomic)
        #endif
    }
    public func remove(_ key: String) {
        try? FileManager.default.removeItem(at: directory.appending(path: key))
    }

    public static var defaultDirectory: URL {
        (try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true))?
            .appending(path: "Murti") ?? URL.temporaryDirectory.appending(path: "Murti")
    }
}
