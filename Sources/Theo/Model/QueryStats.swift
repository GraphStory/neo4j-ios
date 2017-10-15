import Foundation
import Bolt
import PackStream

public struct QueryStats {

    public let propertiesSetCount: UInt64
    public let labelsAddedCount: UInt64
    public let nodesCreatedCount: UInt64

    init(response: Response) {

        var setPSC: UInt64 = 0
        var setLAC: UInt64 = 0
        var setNCC: UInt64 = 0

        for item in response.items {
            if let map = item as? Map,
               let stats = map.dictionary["stats"] as? Map,
               let propertiesSetCount = stats.dictionary["properties-set"]?.uintValue(),
               let labelsAddedCount = stats.dictionary["labels-added"]?.uintValue(),
               let nodesCreatedCount = stats.dictionary["nodes-created"]?.uintValue() {

                setPSC = propertiesSetCount
                setLAC = labelsAddedCount
                setNCC = nodesCreatedCount
                break
            }
        }

        self.propertiesSetCount = setPSC
        self.labelsAddedCount = setLAC
        self.nodesCreatedCount = setNCC
    }


}
