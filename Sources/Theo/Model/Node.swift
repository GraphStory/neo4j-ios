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

    private var updatedProperties: [String: PackProtocol] = [:]
    private var deletedPropertyKeys = Set<String>()
    private var updatedLabels: [String] = []


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
    public func createRequest(withReturnStatement: Bool = true, nodeAlias: String = "node") -> Request {
        let query = createRequestQuery(withReturnStatement: withReturnStatement, nodeAlias: nodeAlias)
        return Request.run(statement: query, parameters: Map(dictionary: self.properties))
    }

    public func createRequestQuery(withReturnStatement: Bool = true, nodeAlias: String = "node", paramSuffix: String = "", withCreate: Bool = true) -> String {
        let labels = self.labels.joined(separator: ":")
        let params = properties.keys.map { "\($0): {\($0)\(paramSuffix)}" }.joined(separator: ", ")

        let query: String
        if withReturnStatement {
            query = "\(withCreate ? "CREATE" : "") (\(nodeAlias):\(labels) { \(params) }) RETURN \(nodeAlias)"
        } else {
            query = "\(withCreate ? "CREATE" : "") (\(nodeAlias):\(labels) { \(params) })"
        }

        return query
    }

    public subscript(key: String) -> PackProtocol? {
        get {
            return self.updatedProperties[key]
        }

        set (newValue) {
            if let newValue = newValue {
                self.properties[key] = newValue
                self.updatedProperties[key] = newValue
                self.deletedPropertyKeys.remove(key)
            } else {
                self.properties.removeValue(forKey: key)
                self.deletedPropertyKeys.insert(key)
            }
            self.modified = true
        }
    }
}

extension Array where Element: Node {

    public func createRequest(withReturnStatement: Bool = true) -> Request {

        var aliases = [String]()
        var queries = [String]()
        var properties = [String: PackProtocol]()
        for i in 0..<self.count {
            let node = self[i]
            let nodeAlias = "node\(i)"
            queries.append(node.createRequestQuery(withReturnStatement: false, nodeAlias: nodeAlias, paramSuffix: "\(i)", withCreate: i == 0))
            aliases.append(nodeAlias)
            for (key, value) in node.properties {
                properties["\(key)\(i)"] = value
            }
        }

        let query: String
        if withReturnStatement {
            query = "\(queries.joined(separator: ", ")) RETURN \(aliases.joined(separator: ","))"
        } else {
            query = queries.joined(separator: ", ")
        }

        return Request.run(statement: query, parameters: Map(dictionary: properties))
    }
}
