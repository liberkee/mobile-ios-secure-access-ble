//
//  Subscriber.swift
//  CommonUtils
//
//  Created by Torsten Lehmann on 24.05.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

/// Wraps the observer closure
class Subscriber<Value> {

    let next: (Value) -> Void

    init(next: @escaping (Value) -> Void) {
        self.next = next
    }
}
