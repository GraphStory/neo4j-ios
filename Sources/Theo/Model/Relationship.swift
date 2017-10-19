import Foundation
import Bolt
import PackStream

public enum RelationshipType {
    case from
    case to
    case bidirectional
}

public class Relationship: ResponseItem {
    public var id: UInt64? = nil
    private var internalAlias: String
    public var modified: Bool = false
    public var updatedTime: Date = Date()
    public var createdTime: Date? = nil

    public var properties: [String: PackProtocol] = [:]
    public var name: String

    public var fromNodeId: UInt64
    public var toNodeId: UInt64
    public var type: RelationshipType

    public init?(fromNode: Node, toNode: Node, name: String, type: RelationshipType) {
        guard let fromNodeId = fromNode.id,
              let toNodeId = toNode.id
            else {
                print("Nodes must have id")
                return nil
        }
        
        self.fromNodeId = fromNodeId
        self.toNodeId = toNodeId
        self.name = name
        self.type = type
        
        self.modified = false
        self.internalAlias = UUID().uuidString.replacingOccurrences(of: "-", with: "")

        self.createdTime = Date()
        self.updatedTime = Date()
    }
    
    init?(data: PackProtocol) {
        if let s = data as? Structure,
            s.signature == 82,
            s.items.count >= 5,
            let relationshipId = s.items[0].uintValue(),
            let fromNodeId = s.items[1].uintValue(),
            let toNodeId = s.items[2].uintValue(),
            let name = s.items[3] as? String,
            let properties = (s.items[4] as? Map)?.dictionary {
            
            self.id = relationshipId
            self.fromNodeId = fromNodeId
            self.toNodeId = toNodeId
            self.name = name
            self.properties = properties
            
            self.modified = false
            self.internalAlias = UUID().uuidString.replacingOccurrences(of: "-", with: "")
            self.type = .from

            self.createdTime = Date()
            self.updatedTime = Date()
            
        } else {
            return nil
        }
        
    }

}
