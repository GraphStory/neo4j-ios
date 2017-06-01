import Foundation

let TheoCypherColumns: String = "columns"
let TheoCypherData: String    = "data"

public struct CypherMeta {

    // MARK: Internal (properties)

    public let columns: Array<String>

    public let data: Array<Any>

    // MARK: Initializers

    init(_ dictionary: Dictionary<String, Any>) throws {

        guard let columns: Array<String> = dictionary.decodingKey(TheoCypherColumns),
            let data: Array<Any> = dictionary.decodingKey(TheoCypherData) else {

                throw JSONSerializationError.invalid("Invalid Dictionary", dictionary)
        }

        self.columns = columns
        self.data = data
    }
}

// MARK: - Printable

extension CypherMeta: CustomStringConvertible {

    public var description: String {
        return "Columns: \(columns), data \(data)"
    }
}
