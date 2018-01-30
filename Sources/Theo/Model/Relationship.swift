import Foundation
import Bolt
import PackStream

public enum RelationshipDirection {
    case from
    case to
}

public class Relationship: ResponseItem {
    public var id: UInt64? = nil
    public private(set) var isModified: Bool = false
    public var updatedTime: Date = Date()
    public var createdTime: Date? = nil

    public private(set) var properties: [String: PackProtocol]
    public var type: String {
        didSet {
            isModified = true
            typeIsModified = true
        }
    }

    private var updatedProperties: [String: PackProtocol] = [:]
    private var removedPropertyKeys = Set<String>()
    private var typeIsModified = false

    public var fromNodeId: UInt64?
    public var fromNode: Node?
    public var toNodeId: UInt64?
    public var toNode: Node?
    public var direction: RelationshipDirection

    public init(fromNode: Node, toNode: Node, type: String, direction: RelationshipDirection = .from, properties: [String: PackProtocol] = [:]) {

        self.fromNode = fromNode
        self.fromNodeId = fromNode.id
        self.toNode = toNode
        self.toNodeId = toNode.id
        self.type = type
        self.direction = direction
        self.properties = properties

        self.isModified = false

        self.createdTime = Date()
        self.updatedTime = Date()
    }

    public init(fromNodeId: UInt64, toNodeId:UInt64, type: String, direction: RelationshipDirection, properties: [String: PackProtocol] = [:]) {

        self.fromNode = nil
        self.fromNodeId = fromNodeId
        self.toNode = nil
        self.toNodeId = toNodeId
        self.type = type
        self.direction = direction
        self.properties = properties

        self.isModified = false

        self.createdTime = Date()
        self.updatedTime = Date()
    }

    init?(data: PackProtocol) {
        if let s = data as? Structure,
            s.signature == 82,
            s.items.count >= 5,
            let relationshipId = s.items[0].uintValue(),
            let fromNodeId = s.items[1].uintValue(),
            let toNodeId = s.items[2].uintValue(),
            let type = s.items[3] as? String,
            let properties = (s.items[4] as? Map)?.dictionary {

            self.id = relationshipId
            self.fromNodeId = fromNodeId
            self.toNodeId = toNodeId
            self.type = type
            self.properties = properties

            self.isModified = false
            self.direction = .from

            self.createdTime = Date()
            self.updatedTime = Date()

        } else {
            return nil
        }

    }

    public func createRequest(withReturnStatement: Bool = true, relatinoshipAlias: String = "rel") -> Request {
        let (query, properties) = createRequestQuery(withReturnStatement: withReturnStatement, relationshipAlias: relatinoshipAlias)
        return Request.run(statement: query, parameters: Map(dictionary: properties))
    }

    public func createRequestQuery(
        withReturnStatement: Bool = true,
        relationshipAlias: String = "rel") -> (String, [String: PackProtocol]) {
        let relationshipAlias = relationshipAlias == "" ? relationshipAlias : "`\(relationshipAlias)`"

        var properties = self.properties

        var params = properties.keys.map { "`\($0)`: {\($0)}" }.joined(separator: ", ")
        if params != "" {
            params = " { \(params) }"
        }

        let uniquingKeysWith: (PackProtocol, PackProtocol) -> PackProtocol = { (_, new) in
            return new
        }

        let fromNodeQuery: String
        if let fromNode = self.fromNode, fromNode.id == nil {
            let (q, fromProps) = fromNode.createRequestQuery(withReturnStatement: false, nodeAlias: "fromNode", paramSuffix: "1", withCreate: true)
            fromNodeQuery = q
            properties.merge(fromProps, uniquingKeysWith: uniquingKeysWith)
        } else {
            guard let fromNodeId = self.fromNodeId else {
                print("fromNodeId was missing in createRequestQuery. Please file a bug")
                return ("", [:])
            }
            fromNodeQuery = "MATCH (fromNode) WHERE id(fromNode) = \(fromNodeId)"
        }

        let toNodeQuery: String
        if let toNode = self.toNode, toNode.id == nil {
            let (q, toProps) = toNode.createRequestQuery(withReturnStatement: false, nodeAlias: "toNode", paramSuffix: "2", withCreate: true)
            toNodeQuery = q
            properties.merge(toProps, uniquingKeysWith: uniquingKeysWith)
        } else {
            guard let toNodeId = self.toNodeId else {
                print("toNodeId was missing in createRequestQuery. Please file a bug")
                return ("", [:])
            }
            toNodeQuery = "MATCH (toNode) WHERE id(toNode) = \(toNodeId)"
        }

        let relQuery: String
        switch direction {
        case .from:
            relQuery = "CREATE (fromNode)-[\(relationshipAlias):`\(type)`\(params)]->(toNode)"
        case .to:
            relQuery = "CREATE (fromNode)<-[\(relationshipAlias):`\(type)`\(params)]-(toNode)"
        }

        let query: String
        if withReturnStatement {
             query = [fromNodeQuery, toNodeQuery, relQuery, "RETURN \(relationshipAlias),`fromNode`,`toNode`"].cypherSorted().joined(separator: "\n")
        } else {
            query = [fromNodeQuery, toNodeQuery, relQuery].cypherSorted().joined(separator: "\n")
        }

        return (query, properties)
    }

    public func updateRequest(withReturnStatement: Bool = true, relationshipAlias: String = "rel") -> Request {
        let (query, properties) = updateRequestQuery(withReturnStatement: withReturnStatement, relationshipAlias: relationshipAlias)
        return Request.run(statement: query, parameters: Map(dictionary: properties))
    }

    public func updateRequestQuery(withReturnStatement: Bool = true, relationshipAlias: String = "rel", paramSuffix: String = "") -> (String, [String:PackProtocol]) {

        guard let id = self.id else {
            print("Error: Cannot create update request for relationship without id. Did you mean to create it?")
            return ("", [:])
        }

        var properties = [String:PackProtocol]()
        let relationshipAlias = relationshipAlias == "" ? relationshipAlias : "`\(relationshipAlias)`"

        var updatedProperties = self.updatedProperties.keys.map { "\(relationshipAlias).`\($0)` = {\($0)\(paramSuffix)}" }.joined(separator: ", ")
        properties.merge( self.updatedProperties.map { key, value in
            return ("\(key)\(paramSuffix)", value)}, uniquingKeysWith: { _, new in return new } )

        if updatedProperties != "" {
            updatedProperties = "SET \(updatedProperties)\n"
        }

        var removedProperties = self.removedPropertyKeys.count == 0 ? "" : self.removedPropertyKeys.map { "\(relationshipAlias).`\($0)`" }.joined(separator: ", ")

        if removedProperties != "" {
            removedProperties = "REMOVE \(removedProperties)\n"
        }

        var query = """
                    MATCH ()-[\(relationshipAlias)]->()
                    WHERE id(\(relationshipAlias)) = \(id)
                    \(updatedProperties)
                    \(removedProperties)
                    """

        if withReturnStatement {
            query = "\(query)\nRETURN \(relationshipAlias)"
        }

        return (query, properties)
    }

    public func setProperty(key: String, value: PackProtocol?) {
        if let value = value {
            self.properties[key] = value
            self.updatedProperties[key] = value
            self.removedPropertyKeys.remove(key)
        } else {
            self.properties.removeValue(forKey: key)
            self.removedPropertyKeys.insert(key)
        }
        self.isModified = true
    }

    public subscript(key: String) -> PackProtocol? {
        get {
            return self.updatedProperties[key] ?? self.properties[key]
        }

        set (newValue) {
            setProperty(key: key, value: newValue)
        }
    }

    public func deleteRequest(relationshipAlias: String = "rel") -> Request {
        let query = deleteRequestQuery(relationshipAlias: relationshipAlias)
        return Request.run(statement: query, parameters: Map(dictionary: [:]))
    }

    public func deleteRequestQuery(relationshipAlias: String = "rel") -> String {

        guard let id = self.id else {
            print("Error: Cannot create delete request for relationship without id. Did you mean to create it?")
            return ""
        }

        let relationshipAlias = relationshipAlias == "" ? relationshipAlias : "`\(relationshipAlias)`"
        let query = """
                    MATCH ()-[\(relationshipAlias)]->()
                    WHERE id(\(relationshipAlias)) = \(id)
                    DELETE \(relationshipAlias)
                    """

        return query
    }

    //MARK: Query
    public static func queryFor(type: String, andProperties properties: [String:PackProtocol], relationshipAlias: String = "rel", skip: UInt64 = 0, limit: UInt64 = 25) -> Request {
        let relationshipAlias = relationshipAlias == "" ? relationshipAlias : "`\(relationshipAlias)`"

        var propertiesQuery = properties.keys.map { "\(relationshipAlias).`\($0)`= {\($0)}" }.joined(separator: "\nAND ")
        if propertiesQuery != "" {
            propertiesQuery = "WHERE " + propertiesQuery
        }

        let skipQuery = skip > 0 ? " SKIP \(skip)" : ""
        let limitQuery = limit > 0 ? " LIMIT \(limit)" : ""

        let query = """
        MATCH (a)-[\(relationshipAlias):`\(type)`]->(b)
        \(propertiesQuery)
        RETURN a,\(relationshipAlias),b\(skipQuery)\(limitQuery)
        """
        return Request.run(statement: query, parameters: Map(dictionary: properties))
    }
}

extension String {
    func beginsWith(_ match: String) -> Bool {
        if self.count < match.count {
            return false
        }

        let begin = self.startIndex
        let end = index(begin, offsetBy: match.count)
        let sut = self[begin..<end].uppercased()
        if sut == match.uppercased() {
            return true
        }
        return false
    }
}

private extension Array {
    func cypherSorted() -> [String] {
        var matches = [String]()
        var creates = [String]()
        var others = [String]()
        var returns = [String]()

        for string in self as? [String] ?? [] {
            if string.beginsWith("MATCH") {
                matches.append(string)
            } else if string.beginsWith("CREATE") {
                creates.append(string)
            } else if string.beginsWith("RETURN") {
                returns.append(string)
            } else {
                others.append(string)
            }
        }

        return matches + creates + others + returns
    }
}

extension Array where Element: Relationship {

    public func createRequest(withReturnStatement: Bool = true) -> Request {

        var returnItems = Set<String>()
        var matchQueries = [String]()
        var createQueries = [String]()
        var createdNodeAliases = [Int:String]()
        var matchedNodeAliases = [UInt64:String]()
        var parameters = [String:PackProtocol]()

        var i = 0
        while i < self.count {
            let relationship = self[i]
            i = i + 1
            let relationshipAlias = "rel\(i)"

            var params = relationship.properties.keys.map {
                parameters["\($0)\(i)"] = relationship.properties[$0]
                return "`\($0)`: {\($0)\(i)}"
            }.joined(separator: ", ")
            if params != "" {
                params = " { \(params) }"
            }

            var fromNodeAlias = "fromNode\(i)"
            var toNodeAlias = "toNode\(i)"

            if let fromNodeId = relationship.fromNodeId ?? relationship.fromNode?.id {
                if let existingFromNodeAlias = matchedNodeAliases[fromNodeId] {
                    fromNodeAlias = existingFromNodeAlias
                } else {
                    matchQueries.append("MATCH (`\(fromNodeAlias)`) WHERE id(`\(fromNodeAlias)`) = \(fromNodeId)")
                    matchedNodeAliases[fromNodeId] = fromNodeAlias
                }
            } else if let fromNode = relationship.fromNode {
                if let existingFromNodeAlias = createdNodeAliases[fromNode.instanceId] {
                    fromNodeAlias = existingFromNodeAlias
                } else {
                    let (query,properties) = fromNode.createRequestQuery(
                        withReturnStatement: false,
                        nodeAlias: fromNodeAlias,
                        paramSuffix: "\(i)",
                        withCreate: false)
                    createQueries.append(query)
                    createdNodeAliases[fromNode.instanceId] = fromNodeAlias
                    parameters.merge( properties, uniquingKeysWith: { _, new in return new } )
                }
            } else {
                print("Could neither find nodeId or node for fromNode - please report this bug")
            }

            if let toNodeId = relationship.toNodeId ?? relationship.toNode?.id {
                if let existingToNodeAlias = matchedNodeAliases[toNodeId] {
                    toNodeAlias = existingToNodeAlias
                } else {
                    matchQueries.append("MATCH (`\(toNodeAlias)`) WHERE id(`\(toNodeAlias)`) = \(toNodeId)")
                    matchedNodeAliases[toNodeId] = toNodeAlias
                }
            } else if let toNode = relationship.toNode {
                if let existingToNodeAlias = createdNodeAliases[toNode.instanceId] {
                    toNodeAlias = existingToNodeAlias
                } else {
                    let (query,properties) = toNode.createRequestQuery(
                        withReturnStatement: false,
                        nodeAlias: toNodeAlias,
                        paramSuffix: "\(i)",
                        withCreate: false)
                    createQueries.append(query)
                    createdNodeAliases[toNode.instanceId] = toNodeAlias
                    parameters.merge( properties, uniquingKeysWith: { _, new in return new } )
                }
            } else {
                print("Could neither find nodeId or node for toNode - please report this bug")
            }

            if relationship.direction == .to {
                createQueries.append("(`\(fromNodeAlias)`)-[\(`relationshipAlias`):`\(relationship.type)`\(params)]->(`\(toNodeAlias)`)")
            } else {
                createQueries.append("(`\(fromNodeAlias)`)<-[\(`relationshipAlias`):`\(relationship.type)`\(params)]-(`\(toNodeAlias)`)")
            }
            returnItems.insert(relationshipAlias)
            returnItems.insert(fromNodeAlias)
            returnItems.insert(toNodeAlias)
        }

        var query: String = matchQueries.joined(separator: "\n") + "\nCREATE " + createQueries.joined(separator: ",\n  ")
        if withReturnStatement {
            query += "\nRETURN \(returnItems.joined(separator: ","))"
        }

        return Request.run(statement: query, parameters: Map(dictionary: parameters))
    }

    /*
    public func updateRequest(withReturnStatement: Bool = true) -> Request {

        var aliases = [String]()
        var queries = [String]()
        var properties = [String: PackProtocol]()
        for i in 0..<self.count {
            let node = self[i]
            let relationshipAlias = "rel\(i)"
            let (query, queryProperties) = node.updateRequestQuery(
                withReturnStatement: false,
                relationshipAlias: relationshipAlias, paramSuffix: "\(i)")
            queries.append(query)
            aliases.append(relationshipAlias)
            for (key, value) in queryProperties {
                properties[key] = value
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

    public func deleteRequest(withReturnStatement: Bool = true) -> Request {

        let ids = self.flatMap { $0.id }.map { "\($0)" }.joined(separator: ", ")
        let relationshipAlias = "rel"

        let query = """
        MATCH (\(relationshipAlias)
        WHERE id(\(relationshipAlias) IN [\(ids)]
        DETACH DELETE \(relationshipAlias)
        """

        return Request.run(statement: query, parameters: Map(dictionary: [:]))
    }
     */

}
