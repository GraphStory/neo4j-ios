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

struct RelationshipMeta: Printable {

    let extensions: [String: AnyObject] = [String: AnyObject]()
    let start: String                   = ""
    let property: String                = ""
    let relationship_self: String       = ""
    let properties: String              = ""
    let type: String                    = ""//TODO: add custom function so it will return RelationshipType
    let end: String                     = ""
    let data: [String: AnyObject]       = [String: AnyObject]()
    
    func relationshipID() -> String {
        
        let pathComponents: Array<String> = self.relationship_self.componentsSeparatedByString("/")
        
        return pathComponents.last!
    }
    
    init(dictionary: Dictionary<String, AnyObject>!) {
        
        for (key: String, value: AnyObject) in dictionary {
            
            switch key {
            case TheoRelationshipExtensionsKey:
                self.extensions = value as Dictionary
            case TheoRelationshipStartKey:
                self.start = value as String
            case TheoRelationshipPropertyKey:
                self.property = value as String
            case TheoRelationshipSelfKey:
                self.relationship_self = value as String
            case TheoRelationshipPropertiesKey:
                self.properties = value as String
            case TheoRelationshipTypeKey:
                self.type = value as String
            case TheoRelationshipEndKey:
                self.end = value as String
            case TheoRelationshipDataKey:
                self.data = value as Dictionary
            default:
                ""
            }
        }
    }
    
    var description: String {
        return "Extensions: \(self.extensions), start \(self.start), property \(self.property), self \(self.relationship_self), properties \(self.properties), type \(self.type), end \(self.end), data \(self.data), relationshipID \(self.relationshipID()))"
    }
}

struct RelationshipType {

    static var KNOWS: String   = "KNOWS"
    static var know: String    = "know"
    static var FRIENDS: String = "FRIENDS"
    static var likes: String   = "likes"
    static var has: String     = "has"
    static var knows: String   = "knows"
    static var LOVES: String   = "LOVES"
}

struct RelationshipDirection {
    
    static var ALL: String = "all"
    static var IN: String  = "in"
    static var OUT: String = "out"
}

class Relationship {

    // MARK: Private Properties

    private (set) var relationshipMeta: RelationshipMeta?
    private (set) var relationshipCreateMeta: [String:AnyObject] = [String:AnyObject]()
    private (set) var relationshipData: [String:AnyObject]       = [String:AnyObject]()

    // MARK: Lazy Properties
    
    lazy var relationshipInfo: [String:AnyObject] = {
        var info: [String:AnyObject] = [String:AnyObject]()
        
        info["to"]   = self.relationshipCreateMeta[RelationshipDataToNodeKey]
        info["type"] = self.relationshipCreateMeta[RelationshipDataTypeKey]

        if (!self.isDataEmpty()) {
            info["data"] = self.relationshipData
        }
        
        return info
    }()

    lazy var fromNode: String = {
        
        if let object: AnyObject = self.relationshipCreateMeta[RelationshipDataFromNodeKey] {
            return object as String
        }

        return ""
    }()
    
    lazy var toNode: String = {
        
        if let object: AnyObject = self.relationshipCreateMeta[RelationshipDataToNodeKey] {
            return object as String
        }
        
        return ""
    }()
    
    lazy var relationshipType: String = {

        if let object: AnyObject = self.relationshipCreateMeta[RelationshipDataTypeKey] {
            return object as String
        }
        
        return ""
    }()

    // MARK: Constructors

    /// Designated Initializer
    ///
    /// :param: Dictionary<String,AnyObject> data
    /// :returns: Relationship
    required init(data: Dictionary<String,AnyObject>?) {
        
        self.relationshipCreateMeta = [String:AnyObject]()
        self.relationshipData       = [String:AnyObject]()
        
        if let dictionaryData: [String:AnyObject] = data {

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
    /// :returns: Relationship
    convenience init() {
        self.init(data: nil)
    }
    
    /// Sets the relationship between two nodes
    ///
    /// :param: Node fromNode
    /// :param: Node toNode
    /// :param: String type (see RelationshipDirection)
    /// :returns: Void
    func relate(fromNode: Node, toNode: Node, type: String) -> Void {
    
        self.relationshipCreateMeta[RelationshipDataFromNodeKey] = fromNode.meta?.create_relationship
        self.relationshipCreateMeta[RelationshipDataToNodeKey]   = toNode.meta?.nodeID()
        self.relationshipCreateMeta[RelationshipDataTypeKey]     = type
    }
    
    /// Gets a specified property for the Relationship
    ///
    /// :param: String propertyName
    /// :returns: AnyObject?
    func getProp(propertyName: String) -> AnyObject? {
        
        if let object: AnyObject = self.relationshipData[propertyName] {
            return object
        }
        
        return nil
    }
    
    /// Sets the property for the relationship
    ///
    /// :param: String propertyName
    /// :param: String propertyValue
    /// :returns: Void
    func setProp(propertyName: String, propertyValue: String) -> Void {
        
        var objectValue: AnyObject = propertyValue as AnyObject
        
        self.relationshipData[propertyName] = objectValue
    }
    
    /// Determine whether the relationship data is empty.
    ///
    /// This is done by checking whether or not the dictionary keys are empty
    ///
    /// :param: String propertyName
    /// :param: String propertyValue
    /// :returns: Bool
    func isDataEmpty() -> Bool {
        return self.relationshipData.keys.isEmpty
    }
}
