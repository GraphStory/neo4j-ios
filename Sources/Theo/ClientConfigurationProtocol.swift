import Foundation
import PackStream

public protocol ClientConfigurationProtocol {

    var hostname: String { get }
    var port: Int { get }
    var username: String { get }
    var password: String { get }
    var encrypted: String { get }
}

extension ClientConfigurationProtocol {
    
    var hostname: String {
        return "localhost"
    }
    
    var port: UInt {
        return 7687
    }
    
    var username: String {
        return "neo4j"
    }
    
    var password: String {
        return "neo4j"
    }
    
    var encrypted: Bool {
        return true
    }
}
