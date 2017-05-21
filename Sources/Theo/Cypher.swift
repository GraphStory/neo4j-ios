import Foundation

open class Cypher {

    var meta: CypherMeta?
    open fileprivate(set) var data: Array<Dictionary<String, Any>> = Array<Dictionary<String, Any>>()

    public required init(metaData: Dictionary<String, Any>?) {

        if let dictionaryData = metaData {

            do {
                self.meta = try CypherMeta(dictionaryData as Dictionary<String, Any>)
            } catch {
                self.meta = nil
            }

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
