import Foundation

public class QueryResult {

    var fields: [String]
    var stats: QueryStats
    var nodes: [UInt64:Node]
    var relationships: [UInt64:Relationship]
    var paths: [Path]
    var responseItemDicts: [[String:ResponseItem]]

    init(fields: [String] = [],
         stats: QueryStats = QueryStats(),
         nodes: [UInt64:Node] = [:],
         relationships: [UInt64:Relationship] = [:],
         paths: [Path] = []) {

        self.fields = fields
        self.stats = stats
        self.nodes = nodes
        self.relationships = relationships
        self.paths = paths
        self.responseItemDicts = [[String:ResponseItem]]()
    }

}
