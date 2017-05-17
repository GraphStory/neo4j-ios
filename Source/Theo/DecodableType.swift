//
//  DecodableType.swift
//  Theo
//
//  Created by Cory D. Wiles on 5/16/17.
//
//

import Foundation

public protocol DecodableType {}

extension String: DecodableType {}
extension Bool: DecodableType {}
extension Int: DecodableType {}
extension Double: DecodableType {}
extension Float: DecodableType {}
extension NSDictionary: DecodableType {}
extension Array: DecodableType {}
extension Dictionary: DecodableType {}
