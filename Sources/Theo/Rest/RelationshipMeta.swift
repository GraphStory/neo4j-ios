import Foundation

let TheoRelationshipExtensionsKey: String = "extensions"
let TheoRelationshipStartKey: String      = "start"
let TheoRelationshipPropertyKey: String   = "property"
let TheoRelationshipSelfKey: String       = "self"
let TheoRelationshipPropertiesKey: String = "properties"
let TheoRelationshipTypeKey: String       = "type"
let TheoRelationshipEndKey: String        = "end"
let TheoRelationshipDataKey: String       = "data"
let TheoRelationshipMetaDataKey: String   = "metadata"

public struct RelationshipMeta: CustomStringConvertible {

    let extensions: [String: Any]
    let start: String
    let property: String
    let relationship_self: String
    let properties: String
    let type: String //TODO: add custom function so it will return RelationshipType
    let end: String
    let data: [String: Any]

    public let metadata: [String: Any]

    public func relationshipID() -> String {

        let pathComponents: Array<String> = self.relationship_self.components(separatedBy: "/")

        return pathComponents.last!
    }

    init(dictionary: Dictionary<String, Any>!) {

        self.extensions         = dictionary[TheoRelationshipExtensionsKey] as! Dictionary
        self.start              = dictionary[TheoRelationshipStartKey]      as! String
        self.property           = dictionary[TheoRelationshipPropertyKey]   as! String
        self.relationship_self  = dictionary[TheoRelationshipSelfKey]       as! String
        self.properties         = dictionary[TheoRelationshipPropertiesKey] as! String
        self.type               = dictionary[TheoRelationshipTypeKey]       as! String
        self.end                = dictionary[TheoRelationshipEndKey]        as! String
        self.data               = dictionary[TheoRelationshipDataKey]       as! Dictionary
        self.metadata           = dictionary[TheoRelationshipMetaDataKey]   as! Dictionary
    }

    public var description: String {
        return "Extensions: \(self.extensions), start \(self.start), property \(self.property), self \(self.relationship_self), properties \(self.properties), type \(self.type), end \(self.end), data \(self.data), relationshipID \(self.relationshipID()), metadata \(self.metadata)"
    }
}
