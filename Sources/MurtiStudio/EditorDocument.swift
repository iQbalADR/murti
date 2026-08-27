import MurtiCore
import Observation

@MainActor @Observable
final class EditorDocument {
    private(set) var root: MurtiNode
    init(root: MurtiNode = MurtiNode(type: "vstack")) { self.root = root }
}
