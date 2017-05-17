//
//  Result.swift
//  Theo
//
//  Created by Cory D. Wiles on 5/17/17.
//
//

import Foundation

public enum TheoResult<T, ResultError: Error> {
    case success(T)
    case failure(ResultError)
}
