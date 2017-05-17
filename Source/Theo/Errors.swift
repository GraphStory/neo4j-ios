//
//  Errors.swift
//  Theo
//
//  Created by Cory D. Wiles on 5/16/17.
//
//

import Foundation

public enum TheoError: Error {
    
    case general(String)
    case emptyresult(String)
    case failedparsing(String)
}

public typealias TheoFetchClosure<T> = (_ result: TheoResult<T, TheoError>) -> Void

public enum JSONSerializationError: Error {
    
    public typealias RawValue = Any
    
    case missing(String)
    case invalid(String, RawValue)
}
