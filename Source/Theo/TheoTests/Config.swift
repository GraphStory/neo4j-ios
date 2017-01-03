//
//  Config.swift
//  Theo
//
//  Created by Cory D. Wiles on 9/21/14.
//  Copyright (c) 2014 Theo. All rights reserved.
//

import Foundation


struct Config {
    let username: String
    let password: String
    let host: String
    
    init(pathToFile: String) {

        do {
            let filePathURL = URL(fileURLWithPath: pathToFile)
            let jsonData = try Data(contentsOf: filePathURL)
            let JSON = try JSONSerialization.jsonObject(with: jsonData, options: [])

            let jsonConfig: [String:String]! = JSON as! [String:String]
            
            self.username = jsonConfig["username"]!
            self.password = jsonConfig["password"]!
            self.host     = jsonConfig["host"]!

        } catch {

            self.username = ""
            self.password = ""
            self.host     = ""

            print("Fetch failed: \(error)")
        }
    }
}
