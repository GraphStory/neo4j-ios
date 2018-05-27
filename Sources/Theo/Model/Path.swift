import Foundation
import Bolt
import PackStream

public typealias Segment = Relationship

public class Path: ResponseItem {

    public var segments: [Segment] = []

    internal var nodes: [Node]
    internal var unboundRelationships: [UnboundRelationship]
    internal var sequence: [Int]

    init?(data: PackProtocol) {
        if let s = data as? Structure,
            s.signature == 80,
            s.items.count >= 3,
            let nodeStructs = (s.items[0] as? List)?.items,
            let unboundRelationshipsStructures = (s.items[1] as? List)?.items,
            let sequenceValues = (s.items[2] as? List)?.items {

            let nodes = nodeStructs.compactMap { Node(data: $0) }
            let unboundRelationships = unboundRelationshipsStructures.compactMap { UnboundRelationship(data: $0) }
            let sequence = sequenceValues.compactMap { $0.intValue() }.compactMap { Int($0) }

            self.nodes = nodes
            self.unboundRelationships = unboundRelationships
            self.sequence = sequence

            assert(sequence.count % 2 == 0) // S must always consist of an even number of integers, or be empty

            generateSegments(fromNodeSequenceIndex: nil)

            self.nodes = []
            self.unboundRelationships = []
            self.sequence = []

        } else {
            return nil
        }
    }

    func generateSegments(fromNodeSequenceIndex: Int?) {
        let fromNodeIndex: Int
        if let fromNodeSequenceIndex = fromNodeSequenceIndex  {
            fromNodeIndex = sequence[fromNodeSequenceIndex]
        } else {
            fromNodeIndex = 0
        }

        let toNodeIndex = sequence[fromNodeIndex + 2]
        let fromNode = nodes[fromNodeIndex]
        let toNode = nodes[toNodeIndex]

        let unboundRelationshipIndex = sequence[fromNodeIndex + 1]
        assert(unboundRelationshipIndex != 0) // S has a range encompassed by (..,-1] and [1,..)
        let unboundRelationship = unboundRelationships[abs(unboundRelationshipIndex) - 1]
        let direction: RelationshipDirection = unboundRelationshipIndex > 0 ? .to : .from
        let segment = Relationship(
            fromNode: fromNode,
            toNode: toNode,
            type: unboundRelationship.type,
            direction: direction,
            properties: unboundRelationship.properties)
        segments.append(segment)

        let fromNodeSequenceIndex = fromNodeSequenceIndex ?? -1
        if sequence.count >= fromNodeSequenceIndex + 4 {
            generateSegments(fromNodeSequenceIndex: fromNodeSequenceIndex + 2)
        }
    }

}
