//
//  Result.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

enum Result<T> {
    case success(T)
    case failure(Swift.Error)
}
