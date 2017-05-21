import Foundation

let TheoCypherColumns: String = "columns"
let TheoCypherData: String    = "data"

public struct CypherMeta: CustomStringConvertible {

    let columns: Array<String>
    let data: Array<Any>

    init(dictionary: Dictionary<String, Any>) {

        self.columns = dictionary[TheoCypherColumns] as! Array
        self.data    = dictionary[TheoCypherData]    as! Array
    }

    public var description: String {
        return "Columns: \(columns), data \(data)"
    }
}

open class Cypher {

    var meta: CypherMeta?
    open fileprivate(set) var data: Array<Dictionary<String, Any>> = Array<Dictionary<String, Any>>()

    public required init(metaData: Dictionary<String, Any>?) {

        if let dictionaryData = metaData {

            self.meta = CypherMeta(dictionary: dictionaryData as Dictionary<String, Any>)

            if let metaForCypher: CypherMeta = self.meta {

                for arrayValues in metaForCypher.data as! Array<Array<Any>> {

                    var cypherDictionary: Dictionary<String, Any> = Dictionary<String, Any>()

                    for (index, value) in arrayValues.enumerated() {

                        let cypherDictionaryKey: String = metaForCypher.columns[index]

                        cypherDictionary[cypherDictionaryKey] = value
                    }

                    self.data.append(cypherDictionary)
                }
            }
        }
    }

    public convenience init() {
        self.init(metaData: nil)
    }
}

// MARK: - Printable

extension Cypher: CustomStringConvertible {

    public var description: String {

        var returnString: String = ""

            for value: Dictionary<String, Any> in self.data {

                for (returnStringKey, returnKeyValue) in value {
                    returnString += " \(returnStringKey): \(returnKeyValue)"
                }
            }

            if let meta: CypherMeta = self.meta {
                returnString += "meta description " + meta.description
            }

            return returnString
    }
}
