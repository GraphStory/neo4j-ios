//
//  Cypher.swift
//  Theo
//
//  Created by Cory D. Wiles on 10/7/14.
//  Copyright (c) 2014 Theo. All rights reserved.
//

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

open class Cypher {

    // MARK: Internal (properties)
    
    var meta: CypherMeta?

    open fileprivate(set) var data: Array<Dictionary<String, Any>> = [[String: Any]]()
    
    // MARK: Initializers
    
    public required init(metaData: Dictionary<String, Any>?) throws {
    
        if let dictionaryData: Dictionary<String, Any> = metaData {

            guard let meta: CypherMeta = try? CypherMeta(dictionaryData as Dictionary<String, Any>) else {
                throw JSONSerializationError.invalid("Invalid Dictionary", dictionaryData)
            }

            self.meta = meta
            
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
