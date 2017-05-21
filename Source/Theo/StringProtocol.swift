//
//  StringProtocol.swift
//  Theo
//
//  Created by Cory D. Wiles on 5/16/17.
//
//

import Foundation

protocol StringProtocol {}

extension String: StringProtocol {}

enum DecodeError: Error {
    
    case noValueForKey(StringProtocol)
    case noValueForFoundationKey(message: String)
}
