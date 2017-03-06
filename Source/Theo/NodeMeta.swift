import Foundation

let TheoNodeExtensions: String                 = "extensions"
let TheoNodePagedTraverse: String              = "paged_traverse"
let TheoNodeLabels: String                     = "labels"
let TheoNodeOutGoingRelationships: String      = "outgoing_relationships"
let TheoNodeTraverse: String                   = "traverse"
let TheoNodeAllTypedRelationships: String      = "all_typed_relationships"
let TheoNodeProperty: String                   = "property"
let TheoNodeAllRelationships: String           = "all_relationships"
let TheoNodeSelf: String                       = "self"
let TheoNodeOutGoingTypedRelationships: String = "outgoing_typed_relationships"
let TheoNodeProperties: String                 = "properties"
let TheoNodeIncomingRelationships: String      = "incoming_relationships"
let TheoNodeIncomingTypedRelationships: String = "incoming_typed_relationships"
let TheoNodeCreateRelationship: String         = "create_relationship"
let TheoNodeData: String                       = "data"
let TheoNodeMetaData: String                   = "metadata"

public struct NodeMeta: CustomStringConvertible {
    
    let extensions: [String: Any]
    let page_traverse: String
    let labels: String
    let outgoing_relationships: String
    let traverse: String
    let all_typed_relationships: String
    let property: String
    let all_relationships: String
    let node_self: String
    let outgoing_typed_relationships: String
    let properties: String
    let incoming_relationships: String
    let incoming_typed_relationships: String
    let create_relationship: String
    let data: [String: Any]
    let metadata: [String: Any]
    
    public func nodeID() -> String {
        
        let pathComponents: Array<String> = self.node_self.components(separatedBy: "/")
        
        return pathComponents.last!
    }
    
    public init(dictionary: Dictionary<String, Any>!) {
        
        self.extensions                     = dictionary[TheoNodeExtensions]                    as! Dictionary
        self.page_traverse                  = dictionary[TheoNodePagedTraverse]                 as! String
        self.labels                         = dictionary[TheoNodeLabels]                        as! String
        self.outgoing_relationships         = dictionary[TheoNodeOutGoingRelationships]         as! String
        self.traverse                       = dictionary[TheoNodeTraverse]                      as! String
        self.all_relationships              = dictionary[TheoNodeAllRelationships]              as! String
        self.all_typed_relationships        = dictionary[TheoNodeAllTypedRelationships]         as! String
        self.property                       = dictionary[TheoNodeProperty]                      as! String
        self.node_self                      = dictionary[TheoNodeSelf]                          as! String
        self.outgoing_typed_relationships   = dictionary[TheoNodeOutGoingTypedRelationships]    as! String
        self.properties                     = dictionary[TheoNodeProperties]                    as! String
        self.incoming_relationships         = dictionary[TheoNodeIncomingRelationships]         as! String
        self.incoming_typed_relationships   = dictionary[TheoNodeIncomingTypedRelationships]    as! String
        self.create_relationship            = dictionary[TheoNodeCreateRelationship]            as! String
        self.data                           = dictionary[TheoNodeData]                          as! Dictionary
        self.metadata                       = dictionary[TheoNodeMetaData]                      as! Dictionary
    }
    
    public var description: String {
        return "Extensions: \(self.extensions), page_traverse \(self.page_traverse), labels \(self.labels), outgoing_relationships \(self.outgoing_relationships), traverse \(self.traverse), all_typed_relationships \(self.all_typed_relationships), all_typed_relationships \(self.all_typed_relationships), property \(self.property), all_relationships \(self.all_relationships), self \(self.node_self), outgoing_typed_relationships \(self.outgoing_typed_relationships), properties \(self.properties), incoming_relationships \(self.incoming_relationships), incoming_typed_relationships \(self.incoming_typed_relationships), create_relationship \(self.create_relationship), data \(self.data), metadata \(self.metadata), nodeID \(self.nodeID())"
    }
}
