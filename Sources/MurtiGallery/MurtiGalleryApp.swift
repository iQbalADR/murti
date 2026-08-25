import SwiftUI

/// The component gallery — a runnable "Storybook" for Murti. It renders JSON
/// examples through `MurtiScreen`, shows the source, reports dispatched actions,
/// and includes a paste-JSON hot-reload harness.
@main
struct MurtiGalleryApp: App {
    var body: some Scene {
        WindowGroup {
            GalleryRootView()
        }
    }
}
