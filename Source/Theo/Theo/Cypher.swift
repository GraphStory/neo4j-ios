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

struct CypherMeta: Printable {
    
    let columns: Array<String> = Array<String>()
    let data: Array<AnyObject> = Array<AnyObject>()
    
    init(dictionary: Dictionary<String, AnyObject>) {
        
        for (key, value) in dictionary {
            
            switch key {
                case TheoCypherColumns:
                    self.columns = value as Array
                case TheoCypherData:
                    self.data = value as Array
                default:
                    ""
            }
        }
    }
    
    var description: String {
        return "Columns: \(columns), data \(data)"
    }
}

class Cypher {

    var meta: CypherMeta?
    private(set) var data: Array<Dictionary<String, AnyObject>> = Array<Dictionary<String, AnyObject>>()
    
    required init(metaData: Dictionary<String, Array<AnyObject>>?) {
    
        if let dictionaryData: [String:[AnyObject]] = metaData {

            self.meta = CypherMeta(dictionary: dictionaryData)
            
            if let metaForCypher: CypherMeta = self.meta {
                
                let keys = metaForCypher.columns

                for arrayValues in metaForCypher.data as Array<Array<AnyObject>> {
                    
                    for (index, value) in enumerate(arrayValues) {

                        var cypherDictionary: Dictionary<String, AnyObject> = Dictionary<String, AnyObject>()
                        let cypherDictionaryKey: String = metaForCypher.columns[index]

                        cypherDictionary[cypherDictionaryKey] = value

                        self.data.append(cypherDictionary)
                    }
                }
            }
        }
    }
    
    convenience init() {
        self.init(metaData: nil)
    }
}

// MARK: - Printable

extension Cypher: Printable {
    
    var description: String {
        
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
