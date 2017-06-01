import Foundation

let RelationshipDataFromNodeKey = "fromNode"
let RelationshipDataToNodeKey   = "toNode"
let RelationshipDataTypeKey     = "type"



public struct RelationshipDirection {

    public static var ALL: String = "all"
    public static var IN: String  = "in"
    public static var OUT: String = "out"
}

public struct Relationship {

    // MARK: Public Properties

    // TODO: MUST find a better way to handle this
    // This is a very unfortunate flag that I need to come back ripping out, but
    // due to the different ways relationship properties are set depending on
    // whether you are creating or updating this becomes a necessary evil
    //
    // The basic gist of it is when you create a relationship, with or without
    // properties then your payload has a parent node of "data"...something like
    //    {
    //      "to" : "http://localhost:7474/db/data/node/10",
    //      "type" : "LOVES",
    //      "data" : {
    //      "foo" : "bar"
    //      }
    //    }
    //
    // however when you are updating a relationship with properties then you don't
    // include the "data" node. Something like:
    //    {
    //      "happy" : false
    //    }
    // This is initalized to false, but if you are upating then you'll have to
    // toggle it. If you forget then the update will fail with a 400

    var updatingProperties: Bool

    // MARK: Private Properties

    fileprivate (set) var relationshipCreateMeta: [String:Any] = [String:Any]()
    fileprivate (set) var relationshipData: [String:Any]       = [String:Any]()

    public let id: UInt64

    // MARK: Lazy Properties

    lazy var relationshipInfo: [String:Any] = {

        var info: [String:Any] = [String:Any]()

        info["to"]   = self.relationshipCreateMeta[RelationshipDataToNodeKey]
        info["type"] = self.relationshipCreateMeta[RelationshipDataTypeKey]

        if (!self.isDataEmpty()) {

            if (self.updatingProperties) {

            } else {
                info["data"] = self.relationshipData as Any?
            }
        }

        return info
    }()

    lazy var fromNode: String = {

        if let object: Any = self.relationshipCreateMeta[RelationshipDataFromNodeKey] {
            return object as! String
        }

        return ""
    }()

    lazy var toNode: String = {

        if let object: Any = self.relationshipCreateMeta[RelationshipDataToNodeKey] {
            return object as! String
        }

        return ""
    }()

    lazy var relationshipType: String = {

        if let object: Any = self.relationshipCreateMeta[RelationshipDataTypeKey] {
            return object as! String
        }

        return ""
    }()

    // MARK: Constructors

    /// Rest Initializer
    ///
    /// - parameter Dictionary<String,Any>: data
    /// - returns: Relationship
    public init(data: Dictionary<String,Any>?) {

        self.relationshipCreateMeta = [String:Any]()
        self.relationshipData       = [String:Any]()
        self.updatingProperties     = false

        if let dictionaryData: [String:Any] = data {

            if let relationshipData = dictionaryData["data"] as? [String:Any] {
                self.relationshipData = relationshipData
            }

            if let relSelf = dictionaryData["self"] as? String,
                let stringId = relSelf.components(separatedBy: "/").last {
                self.id = UInt64(stringId) ?? 0
            } else {
                self.id = 0
            }
        }

        else {
            self.id = 0
        }
    }

    /// Convenience initializer
    ///
    /// calls init(data:) with the param value as nil
    ///
    /// - returns: Relationship
    public init() {
        self.init(data: nil)
    }

    /// Sets the relationship between two nodes
    ///
    /// - parameter Node: fromNode
    /// - parameter Node: toNode
    /// - parameter String: type (see RelationshipDirection)
    /// - returns: Void
    public mutating func relate(_ fromNode: Node, toNode: Node, type: String) -> Void {

        self.relationshipCreateMeta[RelationshipDataFromNodeKey] = "\(fromNode.id)"
        self.relationshipCreateMeta[RelationshipDataToNodeKey]   = "\(toNode.id)"
        self.relationshipCreateMeta[RelationshipDataTypeKey]     = type as Any?
    }

    /// A list of available properties for Relationship
    ///
    /// - returns: [String]
    public var allProperties: [String] {
        get {
            return relationshipData.map({ (key, _) -> String in
                return key
            })
        }
    }

    /// Gets a specified property for the Relationship
    ///
    /// - parameter String: propertyName
    /// - returns: Any?
    public func getProp(_ propertyName: String) -> Any? {

        if let object: Any = self.relationshipData[propertyName] {
            return object
        }

        return nil
    }

    /// Unsets the property for the relationship
    ///
    /// - parameter String: propertyName
    /// - returns: Void
    public mutating func removeProp(_ propertyName: String) -> Void {

        self.relationshipData.removeValue(forKey: propertyName)
    }

    /// Sets the property for the relationship. Use value nil to unset it
    ///
    /// - parameter String: propertyName
    /// - parameter String: propertyValue
    /// - returns: Void
    public mutating func setProp(_ propertyName: String, propertyValue: Any?) -> Void {

        if let propertyValue = propertyValue {
            let objectValue: Any = propertyValue
            self.relationshipData[propertyName] = objectValue

        } else {
            removeProp(propertyName)
        }
    }

    /// Equivalent subscripts
    public subscript(propertyName: String) -> Any? {
        get {
            return getProp(propertyName)
        }

        set {
            setProp(propertyName, propertyValue: newValue)
        }
    }

    /// Determine whether the relationship data is empty.
    ///
    /// This is done by checking whether or not the dictionary keys are empty
    ///
    /// - parameter String: propertyName
    /// - parameter String: propertyValue
    /// - returns: Bool
    public func isDataEmpty() -> Bool {
        return self.relationshipData.keys.isEmpty
    }
}

// MARK: - Printable

extension Relationship: CustomStringConvertible {

    public var description: String {

        var returnString: String = ""

        for (key, value) in self.relationshipData {
            returnString += "\(key): \(value) "
        }

        for (key, value) in self.relationshipCreateMeta {
            returnString += "\(key): \(value) "
        }

        return returnString
    }
}
