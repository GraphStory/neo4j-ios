import Foundation

public enum JSONSerializationError: Error {

    public typealias RawValue = Any

    case missing(String)
    case invalid(String, RawValue)
}
