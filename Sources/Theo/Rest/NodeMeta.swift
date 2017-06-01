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

public struct NodeMeta {

    // MARK: Internal (properties)

    let extensions: [String: Any]

    let page_traverse: String

    let labels: String

    var outgoing_relationships: String

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

    // MARK: Public (properties)

    public var nodeID: String {

        let pathComponents: Array<String> = self.node_self.components(separatedBy: "/")

        return pathComponents.last!
    }

    // MARK: Initializers

    public init(_ dictionary: Dictionary<String, Any>) throws {

        guard let extensions: Dictionary<String, Any> = dictionary.decodingKey(TheoNodeExtensions),
            let pageTraverse: String = dictionary.decodingKey(TheoNodePagedTraverse),
            let labels: String = dictionary.decodingKey(TheoNodeLabels),
            let outgoingRelationships: String = dictionary.decodingKey(TheoNodeOutGoingRelationships),
            let traverse: String = dictionary.decodingKey(TheoNodeTraverse),
            let allRelationships: String = dictionary.decodingKey(TheoNodeAllRelationships),
            let allTypedRelationships: String = dictionary.decodingKey(TheoNodeAllTypedRelationships),
            let property: String = dictionary.decodingKey(TheoNodeProperty),
            let nodeSelf: String = dictionary.decodingKey(TheoNodeSelf),
            let outgoingTypedRelationships: String = dictionary.decodingKey(TheoNodeOutGoingTypedRelationships),
            let properties: String = dictionary.decodingKey(TheoNodeProperties),
            let incomingRelationships: String = dictionary.decodingKey(TheoNodeIncomingRelationships),
            let incomingTypedRelationships: String = dictionary.decodingKey(TheoNodeIncomingTypedRelationships),
            let createRelationship: String = dictionary.decodingKey(TheoNodeCreateRelationship),
            let data: Dictionary<String, Any> = dictionary.decodingKey(TheoNodeData),
            let metaData: Dictionary<String, Any> = dictionary.decodingKey(TheoNodeMetaData) else {

                throw JSONSerializationError.invalid("Invalid Dictionary", dictionary)
        }

        self.extensions = extensions
        self.page_traverse = pageTraverse
        self.labels = labels
        self.outgoing_relationships = outgoingRelationships
        self.traverse = traverse
        self.all_relationships = allRelationships
        self.all_typed_relationships = allTypedRelationships
        self.property = property
        self.node_self = nodeSelf
        self.outgoing_relationships = outgoingRelationships
        self.outgoing_typed_relationships = outgoingTypedRelationships
        self.properties = properties
        self.incoming_relationships = incomingRelationships
        self.incoming_typed_relationships = incomingTypedRelationships
        self.create_relationship = createRelationship
        self.data = data
        self.metadata = metaData
    }
}

extension NodeMeta: CustomStringConvertible {

    public var description: String {
        return "Extensions: \(self.extensions), page_traverse \(self.page_traverse), labels \(self.labels), outgoing_relationships \(self.outgoing_relationships), traverse \(self.traverse), all_typed_relationships \(self.all_typed_relationships), all_typed_relationships \(self.all_typed_relationships), property \(self.property), all_relationships \(self.all_relationships), self \(self.node_self), outgoing_typed_relationships \(self.outgoing_typed_relationships), properties \(self.properties), incoming_relationships \(self.incoming_relationships), incoming_typed_relationships \(self.incoming_typed_relationships), create_relationship \(self.create_relationship), data \(self.data), metadata \(self.metadata), nodeID \(self.nodeID)"
    }
}
