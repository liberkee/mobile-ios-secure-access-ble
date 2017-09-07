//
//  Result.swift
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

public enum Result<T> {
    case success(T)
    case failure(Swift.Error)
}
