//
//  Relationship.swift
//  Theo
//
//  Created by Cory D. Wiles on 9/22/14.
//  Copyright (c) 2014 Theo. All rights reserved.
//

import Foundation

let RelationshipDataFromNodeKey = "fromNode"
let RelationshipDataToNodeKey   = "toNode"
let RelationshipDataTypeKey     = "type"

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

public struct RelationshipType {

    public static var KNOWS: String   = "KNOWS"
    public static var know: String    = "know"
    public static var FRIENDS: String = "FRIENDS"
    public static var likes: String   = "likes"
    public static var has: String     = "has"
    public static var knows: String   = "knows"
    public static var LOVES: String   = "LOVES"
}

public struct RelationshipDirection {
    
    public static var ALL: String = "all"
    public static var IN: String  = "in"
    public static var OUT: String = "out"
}

open class Relationship {

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

    open fileprivate (set) var relationshipMeta: RelationshipMeta?
    fileprivate (set) var relationshipCreateMeta: [String:Any] = [String:Any]()
    fileprivate (set) var relationshipData: [String:Any]       = [String:Any]()

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

    /// Designated Initializer
    ///
    /// - parameter Dictionary<String,Any>: data
    /// - returns: Relationship
    public required init(data: Dictionary<String,Any>?) {
        
        self.relationshipCreateMeta = [String:Any]()
        self.relationshipData       = [String:Any]()
        self.updatingProperties     = false
        
        if let dictionaryData: [String:Any] = data {

            self.relationshipMeta = RelationshipMeta(dictionary: dictionaryData)
            
            if let metaForRelationship = self.relationshipMeta {
                self.relationshipData = metaForRelationship.data
            }
        }
    }
    
    /// Convenience initializer
    ///
    /// calls init(data:) with the param value as nil
    ///
    /// - returns: Relationship
    public convenience init() {
        self.init(data: nil)
    }
    
    /// Sets the relationship between two nodes
    ///
    /// - parameter Node: fromNode
    /// - parameter Node: toNode
    /// - parameter String: type (see RelationshipDirection)
    /// - returns: Void
    open func relate(_ fromNode: Node, toNode: Node, type: String) -> Void {
    
        self.relationshipCreateMeta[RelationshipDataFromNodeKey] = fromNode.meta?.create_relationship as Any?
        self.relationshipCreateMeta[RelationshipDataToNodeKey]   = toNode.meta?.nodeID() as Any?
        self.relationshipCreateMeta[RelationshipDataTypeKey]     = type as Any?
    }
    
    /// Gets a specified property for the Relationship
    ///
    /// - parameter String: propertyName
    /// - returns: Any?
    open func getProp(_ propertyName: String) -> Any? {
        
        if let object: Any = self.relationshipData[propertyName] {
            return object
        }
        
        return nil
    }
    
    /// Sets the property for the relationship
    ///
    /// - parameter String: propertyName
    /// - parameter String: propertyValue
    /// - returns: Void
    open func setProp(_ propertyName: String, propertyValue: Any) -> Void {
        
        let objectValue: Any = propertyValue
        
        self.relationshipData[propertyName] = objectValue
    }
    
    /// Determine whether the relationship data is empty.
    ///
    /// This is done by checking whether or not the dictionary keys are empty
    ///
    /// - parameter String: propertyName
    /// - parameter String: propertyValue
    /// - returns: Bool
    open func isDataEmpty() -> Bool {
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
        
        if let meta: RelationshipMeta = self.relationshipMeta {
            returnString += meta.description
        }
        
        for (key, value) in self.relationshipCreateMeta {
            returnString += "\(key): \(value) "
        }
        
        return returnString
    }
}
