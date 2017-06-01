import Foundation
import PackStream

public struct Node {

    // MARK: Private Setters and Public Getters

    fileprivate (set) var nodeData: [String:Any] = [String:Any]()
    fileprivate (set) var labels: [String] = [String]()
    public let id: UInt64

    // MARK: Constructors

    /// Initializer for Rest
    ///
    /// - parameter Dictionary<String,Any>?: data
    /// - returns: Node
    public init(data: Dictionary<String,Any>?) {

        if let dictionaryData: [String:Any] = data {

            if let properties = dictionaryData[TheoNodeData] as? [String:Any] {
                self.nodeData = properties
            }
            if let nodeSelf = dictionaryData[TheoNodeSelf] as? String,
                let nodeId = nodeSelf.components(separatedBy: "/").last {
                self.id = UInt64(nodeId) ?? 0
            } else {
                self.id = 0
            }

        } else {
            self.id = 0
        }
    }


    public init(id: UInt64, labels: [String], properties: [String: PackProtocol]) {
        self.id = id
        self.labels = labels
        self.nodeData = properties
    }

    /// Convenience initializer
    ///
    /// calls init(data:) with the param value as nil
    ///
    /// - returns: Node
    public init() {
        self.init(data: nil)
    }

    /// A list of available properties for Node
    ///
    /// - returns: [String]
    public var allProperties: [String] {
        get {
            return nodeData.map({ (key, _) -> String in
                return key
            })
        }
    }

    /// Gets a specified property for the Node
    ///
    /// - parameter String: propertyName
    /// - returns: Any?
    public func getProp(_ propertyName: String) -> Any? {

        if let object: Any = self.nodeData[propertyName] {
            return object
        }

        return nil
    }

    /// Unsets the property for the node
    ///
    /// - parameter String: propertyName
    /// - returns: Void
    public mutating func removeProp(_ propertyName: String) -> Void {

        self.nodeData.removeValue(forKey: propertyName)
    }

    /// Sets the property for the node. Use value nil to unset it
    ///
    /// - parameter String: propertyName
    /// - parameter String: propertyValue
    /// - returns: Void
    public mutating func setProp(_ propertyName: String, propertyValue: Any?) -> Void {

        if let propertyValue = propertyValue {
            let objectValue: Any = propertyValue
            self.nodeData[propertyName] = objectValue

        } else {
            removeProp(propertyName)
        }
    }

    /// Equivalent subscripts
    public subscript(propertyName: String) -> Any? {
        get {
            return getProp(propertyName)
        }

        set {
            setProp(propertyName, propertyValue: newValue)
        }
    }

    /// Adds label to array of labels for the node
    ///
    /// - parameter String: label
    /// - returns: Void
    public mutating func addLabel(_ label: String) -> Void {
        self.labels.append(label)
    }

    /// Adds labels to existing array of labels for the node
    ///
    /// - parameter Array<String>: labels
    /// - returns: Void
    public mutating func addLabels(_ labels: Array<String>) -> Void {

        let newLabels = Array([self.labels, labels].joined())
        self.labels = newLabels
    }

    /// Returns whether or not the nodeData is empty
    ///
    /// This is done by checking for empty keys array
    ///
    /// - returns: Bool
    public func isEmpty() -> Bool {
        return self.nodeData.keys.isEmpty
    }

    /// Returns whether the current node has labels
    ///
    /// - returns: Bool
    public func hasLabels() -> Bool {
        return self.labels.isEmpty
    }
}

// MARK: - Printable

extension Node: CustomStringConvertible {

    public var description: String {

        var returnString: String = ""

        for (key, value) in self.nodeData {
            returnString += "\(key): \(value) "
        }

        return returnString
    }
}
