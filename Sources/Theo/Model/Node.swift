import Foundation
import Bolt
import PackStream

public protocol ResponseItem {}

public class Node: ResponseItem {
    public var id: UInt64? = nil

    /// Alias used when generating queries
    internal var internalAlias: String
    public var modified: Bool = false
    public var updatedTime: Date = Date()
    public var createdTime: Date? = nil

    public var properties: [String: PackProtocol] = [:]
    public var labels: [String] = []

    public init(
        labels: [String],
        properties: [String: PackProtocol]) {
        
        self.labels = labels
        self.properties = properties
        
        self.modified = false
        self.internalAlias = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        self.createdTime = Date()
        self.updatedTime = Date()
    }
    
    init?(data: PackProtocol) {
        if let s = data as? Structure,
            s.signature == 78,
            s.items.count >= 3,
            let nodeId = s.items[0].uintValue(),
            let labelsList = s.items[1] as? List,
            let properties = (s.items[2] as? Map)?.dictionary {
            let labels = labelsList.items.flatMap { $0 as? String }

            self.id = nodeId
            self.labels = labels
            self.properties = properties
            self.modified = false
            self.internalAlias = UUID().uuidString.replacingOccurrences(of: "-", with: "")

            self.createdTime = Date()
            self.updatedTime = Date()

        } else {
            return nil
        }
    }
    
    public func createRequest() -> Request {
        let labels = self.labels.joined(separator: ":")
        let params = properties.keys.map { "\($0): {\($0)}" }.joined(separator: ",")
        
        let query = "CREATE (node:\(labels) { \(params) }) RETURN node"
        print(query)
        return Request.run(statement: query, parameters: Map(dictionary: self.properties))
    }
}
