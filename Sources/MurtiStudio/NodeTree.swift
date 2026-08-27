import Foundation
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

    /// A copy with `child` appended to the children of `parentID`.
    func insertingChild(_ child: MurtiNode, into parentID: String) -> MurtiNode {
        if id == parentID { return withChildren(children + [child]) }
        return withChildren(children.map { $0.insertingChild(child, into: parentID) })
    }

    /// A copy with child `targetID` swapped with the sibling `delta` positions away
    /// within its parent (no-op if that position is out of range). Callers pass ±1
    /// for adjacent moves.
    func movingChild(_ targetID: String, by delta: Int) -> MurtiNode {
        if let index = children.firstIndex(where: { $0.id == targetID }) {
            let target = index + delta
            guard target >= 0, target < children.count else { return self }
            var moved = children
            moved.swapAt(index, target)
            return withChildren(moved)
        }
        return withChildren(children.map { $0.movingChild(targetID, by: delta) })
    }

    /// A copy where every node has an id: existing ids are kept, missing ones get a UUID.
    func withEnsuredIDs() -> MurtiNode {
        MurtiNode(id: id ?? UUID().uuidString, type: type, props: props,
                  children: children.map { $0.withEnsuredIDs() }, action: action)
    }

    /// A copy with all ids removed, for clean exported JSON.
    func strippingIDs() -> MurtiNode {
        MurtiNode(id: nil, type: type, props: props,
                  children: children.map { $0.strippingIDs() }, action: action)
    }
}
