import Foundation

public class QueryResult {

    public var fields: [String]
    public var stats: QueryStats
    public var nodes: [UInt64:Node]
    public var relationships: [UInt64:Relationship]
    public var paths: [Path]
    public var rows: [[String:ResponseItem]]

    public init(fields: [String] = [],
         stats: QueryStats = QueryStats(),
         nodes: [UInt64:Node] = [:],
         relationships: [UInt64:Relationship] = [:],
         paths: [Path] = []) {

        self.fields = fields
        self.stats = stats
        self.nodes = nodes
        self.relationships = relationships
        self.paths = paths
        self.rows = [[String:ResponseItem]]()
    }

}
