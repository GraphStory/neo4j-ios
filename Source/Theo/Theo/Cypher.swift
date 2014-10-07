//
//  Cypher.swift
//  Theo
//
//  Created by Cory D. Wiles on 10/7/14.
//  Copyright (c) 2014 Theo. All rights reserved.
//

import Foundation

let TheoCypherColumns: String = "columns"
let TheoCypherData: String = "data"

struct CypherMeta: Printable {
    
    let columns: Array<String> = Array<String>()
    let data: Array<Any>    = Array<Any>()
    
    init(dictionary: Dictionary<String, Array<Any>>) {
        
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
    private(set) var data: Array<Dictionary<String, Any>> = Array<Dictionary<String, Any>>()
    
    required init(metaData: Dictionary<String, Array<Any>>?) {
    
        if let dictionaryData: [String:[Any]] = metaData {

            self.meta = CypherMeta(dictionary: dictionaryData)
            
            if let metaForCypher: CypherMeta = self.meta {
                
                let keys = metaForCypher.columns

                for arrayValues in metaForCypher.data as Array<Array<Any>> {
                    
                    for (index, value) in enumerate(arrayValues) {

                        var cypherDictionary: Dictionary<String, Any> = Dictionary<String, Any>()
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
