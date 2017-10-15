import Foundation

public class Node {
    public var id: UInt64? = nil

    /// Alias used when generating queries
    internal var internalAlias: String = UUID().uuidString // TODO: without the "-"
    public var modified: Bool = false
    public var updatedTime: Date = Date()
    public var createdTime: Date? = nil

    public var properties: [String: Any] = [:]
    public var labels: [String] = []

}
