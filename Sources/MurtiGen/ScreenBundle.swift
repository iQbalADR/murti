import Foundation
import MurtiBuilder
import MurtiCore

/// A set of authored screens turned into validated JSON files (`<key>.json`).
public struct ScreenBundle {
    public struct File {
        public let name: String
        public let data: Data
    }

    private let screens: [Screen]
    public init(screens: [Screen]) { self.screens = screens }

    /// Validate every screen and return its `<key>.json` bytes. Throws on the first
    /// invalid screen so a bad bundle never ships.
    public func files() throws -> [File] {
        try screens.map { screen in
            try screen.validated()
            return File(name: "\(screen.payload.screen.key).json", data: try screen.jsonData())
        }
    }

    /// Write the bundle to a directory.
    public func write(to directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for file in try files() {
            try file.data.write(to: directory.appending(path: file.name))
        }
    }
}
