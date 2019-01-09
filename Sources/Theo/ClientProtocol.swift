import Foundation
import Result
import Bolt
import PackStream

public protocol ClientProtocol: class {
    func connect(completionBlock: ((Result<Bool, AnyError>) -> ())?)
    func connectSync() -> Result<Bool, AnyError>
    func disconnect()
    func execute(request: Request, completionBlock: ((Result<(Bool, QueryResult), AnyError>) -> ())?)
    func executeWithResult(request: Request, completionBlock: ((Result<(Bool, QueryResult), AnyError>) -> ())?)
    func executeCypher(_ query: String, params: Dictionary<String,PackProtocol>?, completionBlock: ((Result<(Bool, QueryResult), AnyError>) -> ())?)
    func executeCypherSync(_ query: String, params: Dictionary<String,PackProtocol>?) -> (Result<QueryResult, AnyError>)
    
    func executeAsTransaction(bookmark: String?, transactionBlock: @escaping (_ tx: Transaction) throws -> ()) throws
    func pullAll(partialQueryResult: QueryResult, completionBlock: ((Result<(Bool, QueryResult), AnyError>) -> ())?)
    func getBookmark() -> String?
    func createAndReturnNode(node: Node, completionBlock: ((Result<Node, AnyError>) -> ())?)
    func createAndReturnNodeSync(node: Node) -> Result<Node, AnyError>
    func createNode(node: Node, completionBlock: ((Result<Bool, AnyError>) -> ())?)
    func createNodeSync(node: Node) -> Result<Bool, AnyError>
    func createAndReturnNodes(nodes: [Node], completionBlock: ((Result<[Node], AnyError>) -> ())?)
    func createAndReturnNodesSync(nodes: [Node]) -> Result<[Node], AnyError>
    func createNodes(nodes: [Node], completionBlock: ((Result<Bool, AnyError>) -> ())?)
    func createNodesSync(nodes: [Node]) -> Result<Bool, AnyError>
    func updateAndReturnNode(node: Node, completionBlock: ((Result<Node, AnyError>) -> ())?)
    func updateAndReturnNodeSync(node: Node) -> Result<Node, AnyError>
    func updateNode(node: Node, completionBlock: ((Result<Bool, AnyError>) -> ())?)
    func performRequestWithNoReturnNode(request: Request, completionBlock: ((Result<Bool, AnyError>) -> ())?)
    func updateNodeSync(node: Node) -> Result<Bool, AnyError>
    func updateAndReturnNodes(nodes: [Node], completionBlock: ((Result<[Node], AnyError>) -> ())?)
    func updateAndReturnNodesSync(nodes: [Node]) -> Result<[Node], AnyError>
    func updateNodes(nodes: [Node], completionBlock: ((Result<Bool, AnyError>) -> ())?)
    func updateNodesSync(nodes: [Node]) -> Result<Bool, AnyError>
    func deleteNode(node: Node, completionBlock: ((Result<Bool, AnyError>) -> ())?)
    func deleteNodeSync(node: Node) -> Result<Bool, AnyError>
    func deleteNodes(nodes: [Node], completionBlock: ((Result<Bool, AnyError>) -> ())?)
    func deleteNodesSync(nodes: [Node]) -> Result<Bool, AnyError>
    func nodeBy(id: UInt64, completionBlock: ((Result<Node?, AnyError>) -> ())?)
    func nodesWith(labels: [String], andProperties properties: [String:PackProtocol], skip: UInt64, limit: UInt64, completionBlock: ((Result<[Node], AnyError>) -> ())?)
    func nodesWith(properties: [String:PackProtocol], skip: UInt64, limit: UInt64, completionBlock: ((Result<[Node], AnyError>) -> ())?)
    func nodesWith(label: String, andProperties properties: [String:PackProtocol], skip: UInt64, limit: UInt64, completionBlock: ((Result<[Node], AnyError>) -> ())?)
    
    func relate(node: Node, to: Node, type: String, properties: [String:PackProtocol], completionBlock: ((Result<Relationship, AnyError>) -> ())?)
    func relateSync(node: Node, to: Node, type: String, properties: [String:PackProtocol]) -> Result<Relationship, AnyError>
    
    func createAndReturnRelationshipsSync(relationships: [Relationship]) -> Result<[Relationship], AnyError>
    func createAndReturnRelationships(relationships: [Relationship], completionBlock: ((Result<[Relationship], AnyError>) -> ())?)
    func createAndReturnRelationshipSync(relationship: Relationship) -> Result<Relationship, AnyError>
    func createAndReturnRelationship(relationship: Relationship, completionBlock: ((Result<Relationship, AnyError>) -> ())?)
    func updateAndReturnRelationship(relationship: Relationship, completionBlock: ((Result<Relationship, AnyError>) -> ())?)
    func updateAndReturnRelationshipSync(relationship: Relationship) -> Result<Relationship, AnyError>
    func updateRelationship(relationship: Relationship, completionBlock: ((Result<Bool, AnyError>) -> ())?)
    func performRequestWithNoReturnRelationship(request: Request, completionBlock: ((Result<Bool, AnyError>) -> ())?)
    func updateRelationshipSync(relationship: Relationship) -> Result<Bool, AnyError>
    /*
    func updateAndReturnRelationships(relationships: [Relationship], completionBlock: ((Result<[Relationship], AnyError>) -> ())?)
    func updateAndReturnRelationshipsSync(relationships: [Relationship]) -> Result<[Relationship], AnyError>
    func updateRelationships(relationships: [Relationship], completionBlock: ((Result<Bool, AnyError>) -> ())?)
    func updateRelationshipsSync(relationships: [Relationship]) -> Result<Bool, AnyError>
     */
    func deleteRelationship(relationship: Relationship, completionBlock: ((Result<Bool, AnyError>) -> ())?)
    func deleteRelationshipSync(relationship: Relationship) -> Result<Bool, AnyError>
    /*
    func deleteRelationships(relationships: [Relationship], completionBlock: ((Result<[Bool], AnyError>) -> ())?)
    func deleteRelationshipsSync(relationships: [Relationship]) -> Result<[Bool], AnyError>
     */
    func relationshipsWith(type: String, andProperties properties: [String:PackProtocol], skip: UInt64, limit: UInt64, completionBlock: ((Result<[Relationship], AnyError>) -> ())?)
    func pullSynchronouslyAndIgnore()
    
    
}
