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
}
