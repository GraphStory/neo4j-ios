import Foundation
import Bolt
import PackStream

public typealias Segment = Relationship

public class Path: ResponseItem {

    var segments: [Segment] = []
    
    init?(data: PackProtocol) {
        return nil //TODO: Implement
    }

}
