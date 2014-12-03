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

        let jsonData: NSData = NSData(contentsOfFile: pathToFile)!
        var jsonError: NSError?
        let JSON: AnyObject? = NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions(0), error: &jsonError) as AnyObject!
        let jsonConfig: [String:String]! = JSON as [String:String]
        
        self.username = jsonConfig["username"]!
        self.password = jsonConfig["password"]!
        self.host     = jsonConfig["host"]!
    }
}
