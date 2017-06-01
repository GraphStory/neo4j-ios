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

    let extensions: [String: Any]
    let node: String
    let node_index: String
    let relationship_index: String
    let extensions_info: String
    let relationship_types: String
    let batch: String
    let cypher: String
    let indexes: String
    let constraints: String
    let transaction: String
    let node_labels: String
    let neo4j_version: String

    init(_ dictionary: Dictionary<String, Any>) throws {

        guard let extensions: Dictionary<String, Any> = dictionary.decodingKey(TheoDBMetaExtensionsKey),
            let node: String = dictionary.decodingKey(TheoDBMetaNodeKey),
            let nodeIndex: String = dictionary.decodingKey(TheoDBMetaNodeIndexKey),
            let relationshipIndex: String = dictionary.decodingKey(TheoDBMetaRelationshipIndexKey),
            let extensionsInfo: String = dictionary.decodingKey(TheoDBMetaExtensionsInfoKey),
            let relationshipTypes: String = dictionary.decodingKey(TheoDBMetaRelationshipTypesKey),
            let batch: String = dictionary.decodingKey(TheoDBMetaBatchKey),
            let cypher: String = dictionary.decodingKey(TheoDBMetaCypherKey),
            let indexes: String = dictionary.decodingKey(TheoDBMetaIndexesKey),
            let constraints: String = dictionary.decodingKey(TheoDBMetaConstraintsKey),
            let transaction: String = dictionary.decodingKey(TheoDBMetaTransactionKey),
            let nodeLabels: String = dictionary.decodingKey(TheoDBMetaNodeLabelsKey),
            let version: String = dictionary.decodingKey(TheoDBMetaNeo4JVersionKey) else {

                throw JSONSerializationError.invalid("Invalid Dictionary", dictionary)
        }

        self.extensions = extensions
        self.node = node
        self.node_index = nodeIndex
        self.relationship_index = relationshipIndex
        self.extensions_info = extensionsInfo
        self.relationship_types = relationshipTypes
        self.batch = batch
        self.cypher = cypher
        self.indexes = indexes
        self.constraints = constraints
        self.transaction = transaction
        self.node_labels = nodeLabels
        self.neo4j_version = version
    }
}

extension DBMeta: CustomStringConvertible {

    public var description: String {
        return "Extensions: \(self.extensions) node: \(self.node) node_index: \(self.node_index) relationship_index: \(self.relationship_index) extensions_info : \(self.extensions_info), relationship_types: \(self.relationship_types) batch: \(self.batch) cypher: \(self.cypher) indexes: \(self.indexes) constraints: \(self.constraints) transaction: \(self.transaction) node_labels: \(self.node_labels) neo4j_version: \(self.neo4j_version)"
    }
}
