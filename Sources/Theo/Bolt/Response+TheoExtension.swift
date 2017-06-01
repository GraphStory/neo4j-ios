import Foundation
import PackStream
import Bolt

public extension Response {
    public func asNode() -> Node? {
        if category != .record ||
            items.count != 1 {
            return nil
        }

        let list = items[0] as? List
        guard let items = list?.items,
            items.count == 1,

            let structure = items[0] as? Structure,
            structure.signature == Response.RecordType.node,
            structure.items.count == 3,

            let nodeId = structure.items.first?.asUInt64(),
            let labelList = structure.items[1] as? List,
            let labels = labelList.items as? [String],
            let propertyMap = structure.items[2] as? Map
            else {
                return nil
        }

        let properties = propertyMap.dictionary

        let node = Node(id: UInt64(nodeId), labels: labels, properties: properties)
        return node
    }
}
