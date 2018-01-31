import Foundation
import PackStream

extension Double: ResponseItem {}
extension Int8: ResponseItem {}
extension Int16: ResponseItem {}
extension Int32: ResponseItem {}
extension Int64: ResponseItem {}
extension Int: ResponseItem {}
extension UInt8: ResponseItem {}
extension UInt16: ResponseItem {}
extension UInt32: ResponseItem {}
extension UInt64: ResponseItem {}
extension UInt: ResponseItem {}
extension List: ResponseItem {}
extension Map: ResponseItem {}
extension Null: ResponseItem {}
extension String: ResponseItem {}
extension Structure: ResponseItem {}

public class Record: ResponseItem  {

    public let entry: PackProtocol

    public init(entry: PackProtocol) {
        self.entry = entry
    }
}
