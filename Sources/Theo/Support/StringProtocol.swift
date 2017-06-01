import Foundation

protocol StringProtocol {}

extension String: StringProtocol {}

enum DecodeError: Error {

    case noValueForKey(StringProtocol)
    case noValueForFoundationKey(message: String)
}
