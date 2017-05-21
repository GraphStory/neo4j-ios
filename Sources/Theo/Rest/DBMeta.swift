import Foundation

let TheoParsingQueueName: String           = "com.theo.client"
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

public struct DBMeta {

    let extensions: [String: Any] //= [String: Any]()
    let node: String                    //= ""
    let node_index: String              //= ""
    let relationship_index: String      //= ""
    let extensions_info: String         //= ""
    let relationship_types: String      //= ""
    let batch: String                   //= ""
    let cypher: String                  //= ""
    let indexes: String                 //= ""
    let constraints: String             //= ""
    let transaction: String             //= ""
    let node_labels: String             //= ""
    let neo4j_version: String           //= ""

    init(dictionary: Dictionary<String, Any>!) {

        self.extensions             = dictionary[TheoDBMetaExtensionsKey]           as! Dictionary
        self.node                   = dictionary[TheoDBMetaNodeKey]                 as! String
        self.node_index             = dictionary[TheoDBMetaNodeIndexKey]            as! String
        self.relationship_index     = dictionary[TheoDBMetaRelationshipIndexKey]    as! String
        self.extensions_info        = dictionary[TheoDBMetaExtensionsInfoKey]       as! String
        self.relationship_types     = dictionary[TheoDBMetaRelationshipTypesKey]    as! String
        self.batch                  = dictionary[TheoDBMetaBatchKey]                as! String
        self.cypher                 = dictionary[TheoDBMetaCypherKey]               as! String
        self.indexes                = dictionary[TheoDBMetaIndexesKey]              as! String
        self.constraints            = dictionary[TheoDBMetaConstraintsKey]          as! String
        self.transaction            = dictionary[TheoDBMetaTransactionKey]          as! String
        self.node_labels            = dictionary[TheoDBMetaNodeLabelsKey]           as! String
        self.neo4j_version          = dictionary[TheoDBMetaNeo4JVersionKey]         as! String
    }
}

extension DBMeta: CustomStringConvertible {

    public var description: String {
        return "Extensions: \(self.extensions) node: \(self.node) node_index: \(self.node_index) relationship_index: \(self.relationship_index) extensions_info : \(self.extensions_info), relationship_types: \(self.relationship_types) batch: \(self.batch) cypher: \(self.cypher) indexes: \(self.indexes) constraints: \(self.constraints) transaction: \(self.transaction) node_labels: \(self.node_labels) neo4j_version: \(self.neo4j_version)"
    }
}
