import Foundation
import PackStream
import Result

public typealias NodeID = String

public protocol ClientProtocol {

    typealias TheoNodeRequestCompletionBlock = (_ result: Result<Node, NSError>) -> Void
    typealias TheoNodeRequestDeleteCompletionBlock = (_ result: Result<Void, NSError>) -> Void
    typealias TheoNodeRequestRelationshipCompletionBlock = (_ result: Result<Relationship, NSError>) -> Void
    typealias TheoRelationshipRequestCompletionBlock = (_ result: Result<Array<Relationship>, NSError>) -> Void
    typealias TheoRawRequestCompletionBlock = (_ result: Result<Any?, NSError>) -> Void
    typealias TheoTransactionCompletionBlock = (_ result: Result<Dictionary<String, Any>, NSError>) -> Void
    typealias TheoCypherQueryCompletionBlock = (_ cypher: Result<Cypher?, NSError>) -> Void

}

public protocol RestClientProtocol {
    
    typealias TheoMetaDataCompletionBlock = (_ metaData: DBMeta?, _ error: NSError?) -> Void
    typealias TheoNodeRequestCompletionBlock = (_ node: Node?, _ error: NSError?) -> Void
    typealias TheoNodeRequestDeleteCompletionBlock = (_ error: NSError?) -> Void
    typealias TheoNodeRequestRelationshipCompletionBlock = (_ relationship: Relationship?, _ error: NSError?) -> Void
    typealias TheoRelationshipRequestCompletionBlock = (_ relationships:Array<Relationship>, _ error: NSError?) -> Void
    typealias TheoRawRequestCompletionBlock = (_ response: Any?, _ error: NSError?) -> Void
    typealias TheoTransactionCompletionBlock = (_ response: Dictionary<String, Any>, _ error: NSError?) -> Void
    typealias TheoCypherQueryCompletionBlock = (_ cypher: Cypher?, _ error: NSError?) -> Void
    
}
