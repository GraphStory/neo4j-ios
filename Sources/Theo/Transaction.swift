import Foundation

public class Transaction {
    
    public var succeed: Bool = true
    public var bookmark: String? = nil
    public var autocommit: Bool = true
    internal var commitBlock: (Bool) throws -> Void = { _ in }
    
    public init() {
    }
    
    public func markAsFailed() {
        succeed = false
    }
}
