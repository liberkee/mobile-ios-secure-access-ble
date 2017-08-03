//
//  SystemClock.swift
//  SecureAccessBLE
//
//  Created by Torsten Lehmann on 03.08.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

protocol SystemClockType {

    func now() -> Date
}

class SystemClock: SystemClockType {

    func now() -> Date {
        return Date()
    }
}
