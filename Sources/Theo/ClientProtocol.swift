import Foundation
import PackStream

public protocol ClientProtocol {

    typealias TheoMetaDataCompletionBlock = (_ metaData: DBMeta?, _ error: NSError?) -> Void
    typealias TheoNodeRequestCompletionBlock = (_ node: Node?, _ error: NSError?) -> Void
    typealias TheoNodeRequestDeleteCompletionBlock = (_ error: NSError?) -> Void
    typealias TheoNodeRequestRelationshipCompletionBlock = (_ relationship: Relationship?, _ error: NSError?) -> Void
    typealias TheoRelationshipRequestCompletionBlock = (_ relationships:Array<Relationship>, _ error: NSError?) -> Void
    typealias TheoRawRequestCompletionBlock = (_ response: Any?, _ error: NSError?) -> Void
    typealias TheoTransactionCompletionBlock = (_ response: Dictionary<String, Any>, _ error: NSError?) -> Void
    typealias TheoCypherQueryCompletionBlock = (_ cypher: Cypher?, _ error: NSError?) -> Void

}
