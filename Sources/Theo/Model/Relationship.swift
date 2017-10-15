import Foundation

public enum RelationshipType {
    case from
    case to
    case bidirectional
}

public class Relationship {
    public var id: UInt64? = nil
    public var modified: Bool = false
    public var updatedTime: Date = Date()
    public var createdTime: Date? = nil

    public var properties: [String: Any] = [:]
    public var labels: [String] = []

    public var fromNode: Node
    public var toNode: Node
    public var type: RelationshipType

    public init(fromNode: Node, toNode: Node, type: RelationshipType) {
        self.fromNode = fromNode
        self.toNode = toNode
        self.type = type
    }
}
