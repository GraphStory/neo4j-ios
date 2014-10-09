//
//  Node.swift
//  Theo
//
//  Created by Cory D. Wiles on 9/19/14.
//  Copyright (c) 2014 Theo. All rights reserved.
//

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

public struct NodeMeta: Printable {
    
    let extensions: [String: AnyObject]      = [String: AnyObject]()
    let page_traverse: String                = ""
    let labels: String                       = ""
    let outgoing_relationships: String       = ""
    let traverse: String                     = ""
    let all_typed_relationships: String      = ""
    let property: String                     = ""
    let all_relationships: String            = ""
    let node_self: String                    = ""
    let outgoing_typed_relationships: String = ""
    let properties: String                   = ""
    let incoming_relationships: String       = ""
    let incoming_typed_relationships: String = ""
    let create_relationship: String          = ""
    let data: [String: AnyObject]            = [String: AnyObject]()
    let metadata: [String: AnyObject]        = [String: AnyObject]()

    public func nodeID() -> String {

        let pathComponents: Array<String> = self.node_self.componentsSeparatedByString("/")

        return pathComponents.last!
    }
    
    public init(dictionary: Dictionary<String, AnyObject>!) {
        
        for (key: String, value: AnyObject) in dictionary {
            
            switch key {
            case TheoNodeExtensions:
                self.extensions = value as Dictionary
            case TheoNodePagedTraverse:
                self.page_traverse = value as String
            case TheoNodeLabels:
                self.labels = value as String
            case TheoNodeOutGoingRelationships:
                self.outgoing_relationships = value as String
            case TheoNodeTraverse:
                self.traverse = value as String
            case TheoNodeAllRelationships:
                self.all_relationships = value as String
            case TheoNodeProperty:
                self.property = value as String
            case TheoNodeAllRelationships:
                self.all_relationships = value as String
            case TheoNodeSelf:
                self.node_self = value as String
            case TheoNodeOutGoingTypedRelationships:
                self.outgoing_typed_relationships = value as String
            case TheoNodeProperties:
                self.properties = value as String
            case TheoNodeIncomingRelationships:
                self.incoming_relationships = value as String
            case TheoNodeIncomingTypedRelationships:
                self.incoming_typed_relationships = value as String
            case TheoNodeCreateRelationship:
                self.create_relationship = value as String
            case TheoNodeData:
                self.data = value as Dictionary
            case TheoNodeMetaData:
                self.metadata = value as Dictionary
            default:
                ""
            }
        }
    }
    
    public var description: String {
        return "Extensions: \(self.extensions), page_traverse \(self.page_traverse), labels \(self.labels), outgoing_relationships \(self.outgoing_relationships), traverse \(self.traverse), all_typed_relationships \(self.all_typed_relationships), all_typed_relationships \(self.all_typed_relationships), property \(self.property), all_relationships \(self.all_relationships), self \(self.node_self), outgoing_typed_relationships \(self.outgoing_typed_relationships), properties \(self.properties), incoming_relationships \(self.incoming_relationships), incoming_typed_relationships \(self.incoming_typed_relationships), create_relationship \(self.create_relationship), data \(self.data), metadata \(self.metadata), nodeID \(self.nodeID())"
    }
}

public class Node {

    // MARK: Private Setters and Public Getters

    private (set) var nodeData: [String:AnyObject] = [String:AnyObject]()
    private (set) var labels: [String] = [String]()

    // MARK: Public Properties
    
    public var meta: NodeMeta? = nil {

        didSet {
        
            if let metaForNode = self.meta {
                self.nodeData = metaForNode.data
            }
        }
    }
    
    // MARK: Constructors
    
    /// Designated Initializer
    ///
    /// :param: Dictionary<String,AnyObject>? data
    /// :returns: Node
    public required init(data: Dictionary<String,AnyObject>?) {
        
        if let dictionaryData: [String:AnyObject] = data {

            self.meta = NodeMeta(dictionary: dictionaryData)
            
            if let metaForNode = self.meta {
                self.nodeData = metaForNode.data
            }
        }
    }
    
    /// Convenience initializer
    ///
    /// calls init(data:) with the param value as nil
    ///
    /// :returns: Node
    public convenience init() {
        self.init(data: nil)
    }
    
    /// Gets a specified property for the Node
    ///
    /// :param: String propertyName
    /// :returns: AnyObject?
    public func getProp(propertyName: String) -> AnyObject? {

        if let object: AnyObject = self.nodeData[propertyName] {
            return object
        }
        
        return nil
    }
    
    /// Sets the property for the relationship
    ///
    /// :param: String propertyName
    /// :param: String propertyValue
    /// :returns: Void
    public func setProp(propertyName: String, propertyValue: AnyObject) -> Void {
        
        var objectValue: AnyObject = propertyValue
        
        self.nodeData[propertyName] = objectValue
    }
    
    /// Adds label to array of labels for the node
    ///
    /// :param: String label
    /// :returns: Void
    public func addLabel(label:String) -> Void {
        self.labels.append(label)
    }
    
    /// Returns whether or not the nodeData is empty
    ///
    /// This is done by checking for empty keys array
    ///
    /// :returns: Bool
    public func isEmpty() -> Bool {
        return self.nodeData.keys.isEmpty
    }

    /// Returns whether the current node has labels
    ///
    /// :returns: Bool
    public func hasLabels() -> Bool {
        return self.labels.isEmpty
    }
}

// MARK: - Printable

extension Node: Printable {
    
    public var description: String {
        
        var returnString: String = ""
            
        for (key, value) in self.nodeData {
            returnString += "\(key): \(value) "
        }
        
        if let meta: NodeMeta = self.meta {
            returnString += meta.description
        }
            
        return returnString
    }
}


