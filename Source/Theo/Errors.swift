//
//  Errors.swift
//  Theo
//
//  Created by Cory D. Wiles on 5/16/17.
//
//

import Foundation

public enum JSONSerializationError: Error {
    
    public typealias RawValue = Any
    
    case missing(String)
    case invalid(String, RawValue)
}
