//
//  BoundedQueue.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

struct BoundedQueue<T> {

    enum Error: Swift.Error {
        case maximumElementsReached
    }

    private let maximumElements: Int
    private var elements = [T]()

    init(maximumElements: Int = 10) {
        self.maximumElements = maximumElements
    }

    var isEmpty: Bool {
        return elements.isEmpty
    }

    mutating func enqueue(_ element: T) throws {
        guard elements.count < maximumElements else {
            throw Error.maximumElementsReached
        }
        elements.append(element)
    }

    mutating func dequeue() -> T? {
        guard let element = elements.first else { return nil }
        elements.removeFirst()
        return element
    }
}
