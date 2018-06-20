//
//  Result.swift
//  CommonUtils
//
//  Created on 06.09.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

/// Represents a success or failure.
/// This should be prefered to using a pair with two optionals
/// as the type system enforces only one possible case at a time.
enum Result<T> {
    case success(T)
    case failure(Swift.Error)
}
