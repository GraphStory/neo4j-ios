import Foundation

public protocol DecodableType {}

extension String: DecodableType {}
extension Bool: DecodableType {}
extension Int: DecodableType {}
extension Double: DecodableType {}
extension Float: DecodableType {}
extension NSDictionary: DecodableType {}
extension Array: DecodableType {}
extension Dictionary: DecodableType {}
