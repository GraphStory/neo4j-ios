//
//  Client.swift
//  Cory D. Wiles
//
//  Created by Cory D. Wiles on 9/14/14.
//  Copyright (c) 2014 Theo. All rights reserved.
//

import Foundation

typealias TheoMetaDataCompletionBlock = (metaData: DBMeta?, error: NSError?) -> Void
typealias TheoNodeRequestCompletionBlock = (node: Node?, error: NSError?) -> Void
typealias TheoNodeRequestDeleteCompletionBlock = (error: NSError?) -> Void
typealias TheoNodeRequestRelationshipCompletionBlock = (relationship: Relationship?, error: NSError?) -> Void
typealias TheoRelationshipRequestCompletionBlock = (relationships:Array<Relationship>, error: NSError?) -> Void
typealias TheoRawRequestCompletionBlock = (response: AnyObject?, error: NSError?) -> Void
typealias TheoTransactionCompletionBlock = (response: Dictionary<String, AnyObject>, error: NSError?) -> Void

let TheoDBMetaExtensionsKey: String        = "extensions"
let TheoDBMetaNodeKey: String              = "node"
let TheoDBMetaNodeIndexKey: String         = "node_index"
let TheoDBMetaRelationshipIndexKey: String = "relationship_index"
let TheoDBMetaExtensionsInfoKey: String    = "extensions_info"
let TheoDBMetaRelationshipTypesKey: String = "relationship_types"
let TheoDBMetaBatchKey: String             = "batch"
let TheoDBMetaCypherKey: String            = "cypher"
let TheoDBMetaIndexesKey: String           = "indexes"
let TheoDBMetaConstraintsKey: String       = "constraints"
let TheoDBMetaTransactionKey: String       = "transaction"
let TheoDBMetaNodeLabelsKey: String        = "node_labels"
let TheoDBMetaNeo4JVersionKey: String      = "neo4j_version"

struct DBMeta: Printable {
  
    let extensions: [String: AnyObject] = [String: AnyObject]()
    let node: String                    = ""
    let node_index: String              = ""
    let relationship_index: String      = ""
    let extensions_info: String         = ""
    let relationship_types: String      = ""
    let batch: String                   = ""
    let cypher: String                  = ""
    let indexes: String                 = ""
    let constraints: String             = ""
    let transaction: String             = ""
    let node_labels: String             = ""
    let neo4j_version: String           = ""

    init(dictionary: Dictionary<String, AnyObject>!) {

        for (key: String, value: AnyObject) in dictionary {
          
            switch key {
                case TheoDBMetaExtensionsKey:
                    self.extensions = value as Dictionary
                case TheoDBMetaNodeKey:
                    self.node = value as String
                case TheoDBMetaNodeIndexKey:
                    self.node_index = value as String
                case TheoDBMetaRelationshipIndexKey:
                    self.relationship_index = value as String
                case TheoDBMetaExtensionsInfoKey:
                    self.extensions_info = value as String
                case TheoDBMetaRelationshipTypesKey:
                    self.relationship_types = value as String
                case TheoDBMetaBatchKey:
                    self.batch = value as String
                case TheoDBMetaCypherKey:
                    self.cypher = value as String
                case TheoDBMetaIndexesKey:
                    self.indexes = value as String
                case TheoDBMetaConstraintsKey:
                    self.constraints = value as String
                case TheoDBMetaTransactionKey:
                    self.transaction = value as String
                case TheoDBMetaNodeLabelsKey:
                    self.node_labels = value as String
                case TheoDBMetaNeo4JVersionKey:
                    self.neo4j_version = value as String
                default:
                    ""
            }
        }
    }
  
    var description: String {
        return "Extensions: \(self.extensions) node: \(self.node) node_index: \(self.node_index) relationship_index: \(self.relationship_index) extensions_info : \(self.extensions_info), relationship_types: \(self.relationship_types) batch: \(self.batch) cypher: \(self.cypher) indexes: \(self.indexes) constraints: \(self.constraints) transaction: \(self.transaction) node_labels: \(self.node_labels) neo4j_version: \(self.neo4j_version)"
    }
}

public class Client {
  
    // MARK: Public properties

    let baseURL: String
    let username: String?
    let password: String?
    
    // MARK: Lazy properties

    lazy private var credentials: NSURLCredential? = {
        
        if (self.username != nil && self.password != nil) {
            return NSURLCredential(user: self.username!, password: self.password!, persistence: NSURLCredentialPersistence.ForSession);
        }
        
        return nil
    }()
  
    // MARK: Constructors
    
    /// Designated initializer
    ///
    /// An expection will be thrown if the baseURL isn't passed in
    /// :param: String baseURL
    /// :param: String? user
    /// :param: String? pass
    /// :returns: Client
    
    // TODO: Move the user/password to a tuple since you can't have one w/o the other
    required public init(baseURL: String, user: String?, pass: String?) {

        assert(!baseURL.isEmpty, "Base url must be set")

        if let u = user {
            self.username = user!
        }

        if let p = pass {
            self.password = pass!
        }

        self.baseURL = baseURL
    }
  
    /// Convenience initializer
    ///
    /// user and pass are nil
    ///
    /// :param: String baseURL
    /// :returns: Client
    convenience public init(baseURL: String) {
        self.init(baseURL: baseURL, user: nil, pass: nil)
    }

    /// Convenience initializer
    ///
    /// baseURL, user and pass are nil thus throwing an exception
    ///
    /// :param: String baseURL
    /// :throws: Exception
    convenience public init() {
        self.init(baseURL: "", user: nil, pass: nil)
    }
  
    // MARK: Public Methods
  
    /// Fetches meta information for the Neo4j instance
    ///
    /// :param: TheoMetaDataCompletionBlock? completionBlock
    /// :returns: Void
    func metaDescription(completionBlock: TheoMetaDataCompletionBlock?) -> Void {

        let metaResource = self.baseURL + "/db/data/"
        let metaURL: NSURL = NSURL(string: metaResource)
        let metaRequest: Request = Request(url: metaURL, credential: self.credentials)

        metaRequest.getResource({(data, response) in
      
            if (completionBlock != nil) {
            
                if let responseData: NSData = data {
              
                    let JSON: AnyObject? = NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.AllowFragments, error: nil) as AnyObject!
                    let jsonAsDictionary: [String:AnyObject]! = JSON as [String:AnyObject]
                    let meta: DBMeta = DBMeta(dictionary: jsonAsDictionary)
              
                    completionBlock!(metaData: meta, error: nil)
                }
            }

       }, errorBlock: {(error, response) in
        
            if (completionBlock != nil) {
                completionBlock!(metaData: nil, error: error)
            }
       })
    }
    
    /// Fetches node for a given ID
    ///
    /// :param: String nodeID
    /// :param: TheoMetaDataCompletionBlock? completionBlock
    /// :returns: Void
    func fetchNode(nodeID: String, completionBlock: TheoNodeRequestCompletionBlock?) -> Void {

        let nodeResource = self.baseURL + "/db/data/node/" + nodeID
        let nodeURL: NSURL = NSURL(string: nodeResource)
        let nodeRequest: Request = Request(url: nodeURL, credential: self.credentials)
        
        nodeRequest.getResource(
            {(data, response) in
            
                if (completionBlock != nil) {
                    
                    if let responseData: NSData = data {
                        
                        let JSON: AnyObject? = NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.AllowFragments, error: nil) as AnyObject!
                        let jsonAsDictionary: [String:AnyObject]! = JSON as [String:AnyObject]
                        let node: Node = Node(data: jsonAsDictionary)
                        
                        completionBlock!(node: node, error: nil)
                    }
                }
            
            }, errorBlock: {(error, response) in
                
                if (completionBlock != nil) {
                    completionBlock!(node: nil, error: error)
                }
        })
    }
    
    /// Saves a new node instance that doesn't have labels
    ///
    /// :param: Node node
    /// :param: TheoMetaDataCompletionBlock? completionBlock
    /// :returns: Void
    func createNode(node: Node, completionBlock: TheoNodeRequestCompletionBlock?) -> Void {
        
        let nodeResource: String = self.baseURL + "/db/data/node"
        let nodeURL: NSURL = NSURL(string: nodeResource)
        let nodeRequest: Request = Request(url: nodeURL, credential: self.credentials)
        
        nodeRequest.postResource(node.nodeData, forUpdate: false,
            {(data, response) in

            if (completionBlock != nil) {
                
                if let responseData: NSData = data {
                    
                    let JSON: AnyObject? = NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.AllowFragments, error: nil) as AnyObject!
                    
                    if let JSONObject: AnyObject = JSON {
                        
                        let jsonAsDictionary: [String:AnyObject] = JSONObject as [String:AnyObject]
                        let node: Node = Node(data:jsonAsDictionary)
                        
                        completionBlock!(node: node, error: nil)
                        
                    } else {
                        
                        completionBlock!(node: nil, error: nil)
                    }
                    
                } else {
                    
                    completionBlock!(node: nil, error: nil)
                }
            }
            
            }, errorBlock: {(error, response) in
                
                if (completionBlock != nil) {
                    completionBlock!(node: nil, error: error)
                }
        })
    }
    
    /// Saves a new node instance with labels
    ///
    /// You have to call this method explicitly or else you'll get a recursion
    /// of the saveNode.
    ///
    /// :param: Node node
    /// :param: Array<String> labels
    /// :param: TheoMetaDataCompletionBlock? completionBlock
    /// :returns: Void
    func createNode(node: Node, labels: Array<String>, completionBlock: TheoNodeRequestCompletionBlock?) -> Void {

        let nodeSaveDispatchGroup: dispatch_group_t = dispatch_group_create()
        var createdNodeWithoutLabels: Node?

        dispatch_group_enter(nodeSaveDispatchGroup)

        self.createNode(node, completionBlock: {(node, error) in
        
            if let returnedNode: Node = node {
                createdNodeWithoutLabels = returnedNode
            }
            
            dispatch_group_leave(nodeSaveDispatchGroup)
        })
        
        dispatch_group_notify(nodeSaveDispatchGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {

            if let nodeWithLabels: Node = createdNodeWithoutLabels {
            
                let nodeID: String = nodeWithLabels.meta!.nodeID()
                let nodeResource: String = self.baseURL + "/db/data/node/" + nodeID + "/labels"
                
                let nodeURL: NSURL = NSURL(string: nodeResource)
                let nodeRequest: Request = Request(url: nodeURL, credential: self.credentials)
                
                nodeRequest.postResource(labels, forUpdate: false,
                    successBlock: {(data, response) in
                        
                        if (completionBlock != nil) {
                            completionBlock!(node: nil, error: nil)
                        }
                    },
                    errorBlock: {(error, response) in
                        
                        if (completionBlock != nil) {
                            completionBlock!(node: nil, error: error)
                        }
                    })
            } else {
                
                if (completionBlock != nil) {
                    completionBlock!(node: nil, error: nil)
                }
            }
        })
    }
    
    /// Update a node for a given set of properties
    ///
    /// :param: Node node
    /// :param: Dictionary<String,String> properties
    /// :param: TheoMetaDataCompletionBlock? completionBlock
    /// :returns: Void
    func updateNode(node: Node, properties: Dictionary<String,AnyObject>, completionBlock: TheoNodeRequestCompletionBlock?) -> Void {

        let nodeID: String = node.meta!.nodeID()
        let nodeResource: String = self.baseURL + "/db/data/node/" + nodeID + "/properties"
        let nodeURL: NSURL = NSURL(string: nodeResource)
        let nodeRequest: Request = Request(url: nodeURL, credential: self.credentials)
        
        nodeRequest.postResource(properties, forUpdate: true,
            successBlock: {(data, response) in
            
                if (completionBlock != nil) {
                    
                    if let responseData: NSData = data {
                        
                        let JSON: AnyObject? = NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.AllowFragments, error: nil) as AnyObject!
                        
                        if let JSONObject: AnyObject = JSON {

                            let jsonAsDictionary: [String:AnyObject] = JSONObject as [String:AnyObject]
                            let node: Node = Node(data:jsonAsDictionary)
                            
                            completionBlock!(node: node, error: nil)

                        } else {

                            completionBlock!(node: nil, error: nil)
                        }

                    } else {

                        completionBlock!(node: nil, error: nil)
                    }
                }
            },
            errorBlock: {(error, response) in
                
                if (completionBlock != nil) {
                    completionBlock!(node: nil, error: error)
                }
        })
    }
    
    //TODO: Need to add in check for relationships
    
    /// Delete node instance. This will fail if there is a set relationship
    ///
    /// :param: Node nodeID
    /// :param: TheoNodeRequestDeleteCompletionBlock? completionBlock
    /// :returns: Void
    func deleteNode(nodeID: String, completionBlock: TheoNodeRequestDeleteCompletionBlock?) -> Void {
    
        let nodeResource: String = self.baseURL + "/db/data/node/" + nodeID
        let nodeURL: NSURL = NSURL(string: nodeResource)
        let nodeRequest: Request = Request(url: nodeURL, credential: self.credentials)
        
        nodeRequest.deleteResource({(data, response) in
                
                if (completionBlock != nil) {
                    
                    if let responseData: NSData = data {
                        completionBlock!(error: nil)
                    }
                }
                
            }, errorBlock: {(error, response) in
                
                if (completionBlock != nil) {
                    completionBlock!(error: error)
                }
        })
    }
    
    /// Fetches the relationships for a a node
    ///
    /// :param: String nodeID
    /// :param: String? direction
    /// :param: Array<String>? types
    /// :param: TheoRelationshipRequestCompletionBlock? completionBlock
    /// :returns: Void
    func fetchRelationshipsForNode(nodeID: String, direction: String?, types: Array<String>?, completionBlock: TheoRelationshipRequestCompletionBlock?) -> Void {
        
        var relationshipResource: String = self.baseURL + "/db/data/node/" + nodeID
        
        if let relationshipQuery: String = direction {

            relationshipResource += "/relationships/" + relationshipQuery

            if let relationshipTypes: [String] = types {
                
                if (relationshipTypes.count == 1) {
                    
                    relationshipResource += "/" + relationshipTypes[0]
                    
                } else {
                    
                    for (index, relationship) in enumerate(relationshipTypes) {
                        relationshipResource += index == 0 ? "/" + relationshipTypes[0] : "&" + relationship
                    }
                }
            }

        } else {

            relationshipResource += "/relationships/" + RelationshipDirection.ALL
        }
        
        let relationshipURL: NSURL = NSURL(string: relationshipResource)
        
        let relationshipRequest: Request = Request(url: relationshipURL, credential: self.credentials)
        var relationshipsForNode: [Relationship] = [Relationship]()
        
        relationshipRequest.getResource(
            {(data, response) in
            
                if (completionBlock != nil) {
                    
                    let JSON: AnyObject? = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments, error: nil) as AnyObject!
                    let jsonAsArray: [[String:AnyObject]]! = JSON as [[String:AnyObject]]
                    
                    for relationshipDictionary: [String:AnyObject] in jsonAsArray {
                        let newRelationship = Relationship(data: relationshipDictionary)
                        relationshipsForNode.append(newRelationship)
                    }

                    completionBlock!(relationships: relationshipsForNode, error: nil)
                }
                
            }, errorBlock: {(error, response) in
        
                if (completionBlock != nil) {
                    completionBlock!(relationships: relationshipsForNode, error: error)
                }
            })
    }

    /// Creates a relationship instance
    ///
    /// :param: Relationship relationship
    /// :param: TheoNodeRequestRelationshipCompletionBlock? completionBlock
    /// :returns: Void
    func createRelationship(relationship: Relationship, completionBlock: TheoNodeRequestRelationshipCompletionBlock?) -> Void {
        
        let relationshipResource: String = relationship.fromNode
        let relationshipURL: NSURL = NSURL(string: relationshipResource)
        let relationshipRequest: Request = Request(url: relationshipURL, credential: self.credentials)
        
        relationshipRequest.postResource(relationship.relationshipInfo, forUpdate: false,
                                         successBlock: {(data, response) in
                                            
                                            if (completionBlock != nil) {

                                                if let responseData: NSData = data {

                                                    let JSON: AnyObject? = NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.AllowFragments, error: nil) as AnyObject!
                                                    let jsonAsDictionary: [String:AnyObject]! = JSON as [String:AnyObject]
                                                    let relationship: Relationship = Relationship(data: jsonAsDictionary)
                                                    
                                                    completionBlock!(relationship: relationship, error: nil)
                                                }
                                            }
                                         
                                         }, errorBlock: {(error, response) in

                                                if (completionBlock != nil) {
                                                    completionBlock!(relationship: nil, error: error)
                                                }
                                         })
    }
    
    /// Updates a relationship instance with a set of properties
    ///
    /// :param: Relationship relationship
    /// :param: Dictionary<String,AnyObject> properties
    /// :param: TheoNodeRequestRelationshipCompletionBlock? completionBlock
    /// :returns: Void
    func updateRelationship(relationship: Relationship, properties: Dictionary<String,AnyObject>, completionBlock: TheoNodeRequestRelationshipCompletionBlock?) -> Void {
    
        let relationshipResource: String = self.baseURL + "/db/data/relationship/" + relationship.relationshipMeta!.relationshipID() + "/properties"
        let relationshipURL: NSURL = NSURL(string: relationshipResource)
        let relationshipRequest: Request = Request(url: relationshipURL, credential: self.credentials)
        
        relationship.updatingProperties = true
        
        for (name, value) in properties {
            relationship.setProp(name, propertyValue: value)
        }
        
        relationshipRequest.postResource(properties, forUpdate: true,
            successBlock: {(data, response) in
                
                if (completionBlock != nil) {
                    
                    if let responseData: NSData = data {
                        
                        let JSON: AnyObject? = NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.AllowFragments, error: nil) as AnyObject!

                        // If the update is successfull then you'll receive a 204 with an empty body
                        completionBlock!(relationship: nil, error: nil)
                    }
                }
                
            }, errorBlock: {(error, response) in
                
                if (completionBlock != nil) {
                    completionBlock!(relationship: nil, error: error)
                }
        })
    }
    
    /// Deletes a relationship instance for a given ID
    ///
    /// :param: String relationshipID
    /// :param: TheoNodeRequestDeleteCompletionBlock? completionBlock
    /// :returns: Void
    func deleteRelationship(relationshipID: String, completionBlock: TheoNodeRequestDeleteCompletionBlock?) -> Void {
    
        let relationshipResource = self.baseURL + "/db/data/relationship/" + relationshipID
        let relationshipURL: NSURL = NSURL(string: relationshipResource)
        let relationshipRequest: Request = Request(url: relationshipURL, credential: self.credentials)

        relationshipRequest.deleteResource({(data, response) in

                                            if (completionBlock != nil) {
                                                
                                                if let responseData: NSData = data {
                                                    completionBlock!(error: nil)
                                                }
                                            }

                                           },
                                           errorBlock: {(error, response) in
                                            
                                            if (completionBlock != nil) {
                                                completionBlock!(error: error)
                                            }
                                           })
    }
    
    /// Executes raw Neo4j statements
    ///
    /// :param: Array<Dictionary<String, AnyObject>> statements
    /// :param: TheoTransactionCompletionBlock? completionBlock
    /// :returns: Void
    func executeTransaction(statements: Array<Dictionary<String, AnyObject>>, completionBlock: TheoTransactionCompletionBlock?) -> Void {
        
        let transactionPayload: Dictionary<String, Array<AnyObject>> = ["statements" : statements]
        let transactionResource = self.baseURL + "/db/data/transaction/commit"
        let transactionURL: NSURL = NSURL(string: transactionResource)
        let transactionRequest: Request = Request(url: transactionURL, credential: self.credentials)
        
        transactionRequest.postResource(transactionPayload, forUpdate: false, successBlock: {(data, response) in
            
            if (completionBlock != nil) {
                
                if let responseData: NSData = data {
                    
                    let JSON: AnyObject? = NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.AllowFragments, error: nil) as AnyObject!
                    let jsonAsDictionary: [String:AnyObject]! = JSON as [String:AnyObject]
                    
                    completionBlock!(response: jsonAsDictionary, error: nil)
                }
            }
            
            }, errorBlock: {(error, response) in
                
                if (completionBlock != nil) {
                    completionBlock!(response: [String:AnyObject](), error: error)
                }
        })
    }
    
    /// Executes a get request for a given endpoint
    ///
    /// :param: String uri
    /// :param: TheoRawRequestCompletionBlock? completionBlock
    /// :returns: Void
    func executeRequest(uri: String, completionBlock: TheoRawRequestCompletionBlock?) -> Void {
        
        let queryResource: String = self.baseURL + "/db/data" + uri
        let queryURL: NSURL = NSURL(string: queryResource)
        let queryRequest: Request = Request(url: queryURL, credential: self.credentials)
        
        queryRequest.getResource(
                {(data, response) in
                    
                    if (completionBlock != nil) {
                        
                        if let responseData: NSData = data {
                            
                            let JSON: AnyObject? = NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.AllowFragments, error: nil)
                            
                            completionBlock!(response: JSON, error: nil)
                        }
                    }
                    
                }, errorBlock: {(error, response) in
                    
                    if (completionBlock != nil) {
                        completionBlock!(response: nil, error: error)
                    }
            })
    }
}
