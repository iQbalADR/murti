import MurtiCore

extension MurtiNode {
    /// A copy with the same identity, type, props, and action but different children.
    func withChildren(_ children: [MurtiNode]) -> MurtiNode {
        MurtiNode(id: id, type: type, props: props, children: children, action: action)
    }

    /// The node with this id, searching self and descendants.
    func find(_ targetID: String) -> MurtiNode? {
        if id == targetID { return self }
        for child in children {
            if let found = child.find(targetID) { return found }
        }
        return nil
    }

    /// A copy with the node identified by `targetID` replaced.
    func replacing(_ targetID: String, with replacement: MurtiNode) -> MurtiNode {
        if id == targetID { return replacement }
        return withChildren(children.map { $0.replacing(targetID, with: replacement) })
    }

    /// A copy with the node `targetID` removed wherever it appears among descendants.
    func removing(_ targetID: String) -> MurtiNode {
        withChildren(children.filter { $0.id != targetID }.map { $0.removing(targetID) })
    }
}
