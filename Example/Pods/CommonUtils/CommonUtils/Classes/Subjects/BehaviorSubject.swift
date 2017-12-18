//
//  BehaviorSubject.swift
//  CommonUtils
//
//  Created on 30.05.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

/// A subject that keeps a current value and sends it on subscribe and on every value change.
/// Can be used for direct 1:n communication between objects.
public class BehaviorSubject<Value> {

    /// The current value of the subject
    public private(set) var value: Value
    private var subscribers = [Subscriber<Value>]()

    /// The initializer for this subject, an initial value is mandatory
    public init(value: Value) {
        self.value = value
    }

    /// Adds a subscriber to every change of the current value.
    /// Sends the current value on subscribe.
    /// Use the returned `Disposable` to remove the subscription.
    public func subscribeNext(_ next: @escaping (Value) -> Void) -> Disposable {
        let subscriber = Subscriber(next: next)
        subscribers.append(subscriber)
        subscriber.next(value)
        return Disposer { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.subscribers.removeObject(subscriber)
        }
    }

    /// Sends every subscriber a new value.
    public func onNext(_ value: Value) {
        self.value = value
        let subscribersCopy = subscribers
        subscribersCopy.forEach { $0.next(value) }
    }
}
