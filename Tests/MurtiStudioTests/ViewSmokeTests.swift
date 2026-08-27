import Testing
@testable import MurtiStudio

@MainActor
@Suite("View smoke")
struct ViewSmokeTests {
    @Test func shellConstructs() { _ = StudioView() }
    @Test func outlineConstructs() { _ = OutlineView(document: EditorDocument()) }
    @Test func inspectorConstructs() { _ = InspectorView(document: EditorDocument()) }
    @Test func paletteConstructs() { _ = PaletteView(document: EditorDocument()) }
}
