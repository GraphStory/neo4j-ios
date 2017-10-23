import Foundation
import Bolt
import PackStream

public class UnboundRelationship: ResponseItem {

    let relIdentity: UInt64
    let type: String
    let properties: [String:PackProtocol]

    init?(data: PackProtocol) {
        if let s = data as? Structure,
            s.signature == 114,
            s.items.count >= 3,
            let relIdentity = s.items[0].uintValue(),
            let type = s.items[1] as? String,
            let properties = (s.items[2] as? Map)?.dictionary {

            self.relIdentity = relIdentity
            self.type = type
            self.properties = properties

        } else {
            return nil
        }
    }

}
