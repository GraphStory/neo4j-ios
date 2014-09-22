//
//  Client.swift
//  Cory D. Wiles
//
//  Created by Cory D. Wiles on 9/14/14.
//  Copyright (c) 2014 Theo. All rights reserved.
//

import Foundation

typealias TheoMetaDataCompletionBlock = (metaData: DBMeta?, error: NSError?) -> Void
typealias TheoNodeRequestCompletionBlock = (metaData: NodeMeta?, node: Node?, error: NSError?) -> Void
typealias TheoNodeRequestDeleteCompletionBlock = (error: NSError?) -> Void

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

    init(dictionaryResponse: Dictionary<String, AnyObject>!) {

        for (key: String, value: AnyObject) in dictionaryResponse {
          
            switch key {
                case "extensions":
                    self.extensions = value as Dictionary
                case "node":
                    self.node = value as String
                case "node_index":
                    self.node_index = value as String
                case "relationship_index":
                    self.relationship_index = value as String
                case "extensions_info":
                    self.extensions_info = value as String
                case "relationship_types":
                    self.relationship_types = value as String
                case "batch":
                    self.batch = value as String
                case "cypher":
                    self.cypher = value as String
                case "indexes":
                    self.indexes = value as String
                case "constraints":
                    self.constraints = value as String
                case "transaction":
                    self.transaction = value as String
                case "node_labels":
                    self.node_labels = value as String
                case "neo4j_version":
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

class Client {
  
    let baseURL: String
    let username: String?
    let password: String?
    var authHeaders: [String:String]?
  
    private lazy var authHeaderString: String = {

        let userPasswordString: String = "\(self.username!):\(self.password!)"
        let userPasswordData: NSData = userPasswordString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        let credentialEncoding: String = userPasswordData.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
        let authString: String = "Basic \(credentialEncoding)"

        return authString
    }()
  
    required init(baseURL: String, user: String?, pass: String?) {

        assert(!baseURL.isEmpty, "Base url must be set")

        if let u = user {
            self.username = user!
        }

        if let p = pass {
            self.password = pass!
        }

        self.baseURL = baseURL

        if (self.username != nil && self.password != nil) {
            self.authHeaders = ["Authorization" : self.authHeaderString]
        }
    }
  
    convenience init(baseURL: String) {
        self.init(baseURL: baseURL, user: nil, pass: nil)
    }
  
    convenience init() {
        self.init(baseURL: "", user: nil, pass: nil)
    }
  
// MARK: Public Methods
  
    func metaDescription(completionBlock: TheoMetaDataCompletionBlock?) -> Void {

        let metaResource = self.baseURL + "/db/data/"
        let metaURL: NSURL = NSURL(string: metaResource)
        let metaRequest: Request = Request(url: metaURL, additionalHeaders: self.authHeaders)

        metaRequest.getResource({(data, response) in
      
            if (completionBlock != nil) {
            
                if let responseData: NSData = data {
              
                    let JSON: AnyObject? = NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.AllowFragments, error: nil) as AnyObject!
                    let jsonAsDictionary: [String:AnyObject]! = JSON as [String:AnyObject]
                    let meta: DBMeta = DBMeta(dictionaryResponse: jsonAsDictionary)
              
                    completionBlock!(metaData: meta, error: nil)
                }
            }

       }, errorBlock: {(error, response) in
        
            if (completionBlock != nil) {
                completionBlock!(metaData: nil, error: error)
            }
       })
    }
    
    func fetchNode(nodeID: String, completionBlock: TheoNodeRequestCompletionBlock?) -> Void {

        let nodeResource = self.baseURL + "/db/data/node/" + nodeID
        let nodeRL: NSURL = NSURL(string: nodeResource)
        let nodeRequest: Request = Request(url: nodeRL, additionalHeaders: self.authHeaders)
        
        nodeRequest.getResource(
            {(data, response) in
            
                if (completionBlock != nil) {
                    
                    if let responseData: NSData = data {
                        
                        let JSON: AnyObject? = NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.AllowFragments, error: nil) as AnyObject!
                        let jsonAsDictionary: [String:AnyObject]! = JSON as [String:AnyObject]
                        let meta: NodeMeta = NodeMeta(dictionaryResponse: jsonAsDictionary)
                        let node: Node = Node(data: meta.data)
                        
                        completionBlock!(metaData: meta, node: node, error: nil)
                    }
                }
            
            }, errorBlock: {(error, response) in
                
                if (completionBlock != nil) {
                    completionBlock!(metaData: nil, node: nil, error: error)
                }
        })
    }
    
    func saveNode(node: Node, completionBlock: TheoNodeRequestCompletionBlock?) -> Void {
    
        let nodeResource = self.baseURL + "/db/data/node"
        let nodeURL: NSURL = NSURL(string: nodeResource)
        let nodeRequest: Request = Request(url: nodeURL, additionalHeaders: self.authHeaders)
        
        nodeRequest.postResource(node.nodeData,
            {(data, response) in

            if (completionBlock != nil) {
                
                if let responseData: NSData = data {
                    
                    let JSON: AnyObject? = NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.AllowFragments, error: nil) as AnyObject!
                    let jsonAsDictionary: [String:AnyObject]! = JSON as [String:AnyObject]
                    let meta: NodeMeta = NodeMeta(dictionaryResponse: jsonAsDictionary)
                    let node: Node = Node(data: meta.data)
                    
                    completionBlock!(metaData: meta, node: node, error: nil)
                }
            }
            
            }, errorBlock: {(error, response) in
                
                if (completionBlock != nil) {
                    completionBlock!(metaData: nil, node: nil, error: error)
                }
        })
    }
    
    //TODO: Need to add in check for relationships
    func deleteNode(nodeID: String, completionBlock: TheoNodeRequestDeleteCompletionBlock?) -> Void {
    
        let nodeResource = self.baseURL + "/db/data/node"
        let nodeURL: NSURL = NSURL(string: nodeResource)
        let nodeRequest: Request = Request(url: nodeURL, additionalHeaders: self.authHeaders)
        
        nodeRequest.deleteResource(nodeID,
            {(data, response) in
                
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
}
