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

public struct CypherMeta: CustomStringConvertible {
    
    let columns: Array<String>
    let data: Array<AnyObject>
    
    init(dictionary: Dictionary<String, AnyObject>) {
        
        self.columns = dictionary[TheoCypherColumns] as! Array
        self.data    = dictionary[TheoCypherData]    as! Array
    }
    
    public var description: String {
        return "Columns: \(columns), data \(data)"
    }
}

public class Cypher {

    var meta: CypherMeta?
    public private(set) var data: Array<Dictionary<String, AnyObject>> = Array<Dictionary<String, AnyObject>>()
    
    public required init(metaData: Dictionary<String, Array<AnyObject>>?) {
    
        if let dictionaryData: [String:[AnyObject]] = metaData {

            self.meta = CypherMeta(dictionary: dictionaryData)
            
            if let metaForCypher: CypherMeta = self.meta {
                
                let keys = metaForCypher.columns

                for arrayValues in metaForCypher.data as! Array<Array<AnyObject>> {

                    var cypherDictionary: Dictionary<String, AnyObject> = Dictionary<String, AnyObject>()
                    
                    for (index, value) in arrayValues.enumerate() {

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
            
            for value: Dictionary<String, AnyObject> in self.data {
                
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
