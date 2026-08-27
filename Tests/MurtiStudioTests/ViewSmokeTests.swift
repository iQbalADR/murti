import Testing
@testable import MurtiStudio

@MainActor
@Suite("View smoke")
struct ViewSmokeTests {
    @Test func shellConstructs() { _ = StudioView() }
    @Test func outlineConstructs() { _ = OutlineView(document: EditorDocument()) }
}
