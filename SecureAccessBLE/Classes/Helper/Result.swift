//
//  Result.swift
//  SecureAccessBLE
//
//  Created by Torsten Lehmann on 07.08.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

enum Result<T> {
    case success(T)
    case error(Swift.Error)
}
