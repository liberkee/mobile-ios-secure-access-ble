//
//  SystemClock.swift
//  SecureAccessBLE
//
//  Created on 03.08.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

protocol SystemClockType {
    func now() -> Date

    func timeIntervalSinceNow(for date: Date) -> TimeInterval
}

class SystemClock: SystemClockType {
    func now() -> Date {
        return Date()
    }

    func timeIntervalSinceNow(for date: Date) -> TimeInterval {
        return date.timeIntervalSinceNow
    }
}
