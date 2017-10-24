import Foundation
import Bolt
import PackStream

public class QueryStats {

    public var propertiesSetCount: UInt64
    public var labelsAddedCount: UInt64
    public var nodesCreatedCount: UInt64

    public var resultAvailableAfter: UInt64
    public var resultConsumedAfter: UInt64
    public var type: String

    public init(propertiesSetCount: UInt64 = 0,
         labelsAddedCount: UInt64 = 0,
         nodesCreatedCount: UInt64 = 0,
         resultAvailableAfter: UInt64 = 0,
         resultConsumedAfter: UInt64 = 0,
         type: String = "") {

        self.propertiesSetCount = propertiesSetCount
        self.labelsAddedCount = labelsAddedCount
        self.nodesCreatedCount = nodesCreatedCount
        self.resultAvailableAfter = resultAvailableAfter
        self.resultConsumedAfter = resultConsumedAfter
        self.type = type
    }

    init?(data: PackProtocol) {

        if let map = data as? Map,
            let stats = map.dictionary["stats"] as? Map,
            let propertiesSetCount = stats.dictionary["properties-set"]?.uintValue(),
            let labelsAddedCount = stats.dictionary["labels-added"]?.uintValue(),
            let nodesCreatedCount = stats.dictionary["nodes-created"]?.uintValue() {

            self.propertiesSetCount = propertiesSetCount
            self.labelsAddedCount = labelsAddedCount
            self.nodesCreatedCount = nodesCreatedCount

            self.resultAvailableAfter = 0
            self.resultConsumedAfter = 0
            self.type = "N/A"
        } else {
            return nil
        }

    }


}
