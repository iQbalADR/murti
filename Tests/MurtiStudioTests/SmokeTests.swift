import Testing
@testable import MurtiStudio

@Suite("MurtiStudio smoke")
struct SmokeTests {
    @MainActor @Test func documentStartsEmptyVStack() {
        #expect(EditorDocument().root.type == "vstack")
    }
}
