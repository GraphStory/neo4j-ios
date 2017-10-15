import Foundation
import Bolt

public enum QueryType: String {
    case read = "r"
    case write "w"
}

public struct QuerySummary {
    let stats: QueryStats?
    let resultConsumedAfterMs: UInt64
    let type: QueryType
}
