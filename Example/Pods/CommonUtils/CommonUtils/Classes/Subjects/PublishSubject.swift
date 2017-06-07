//
//  PublishSubject.swift
//  CommonUtils
//
//  Created by Torsten Lehmann on 30.05.17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

/// A subject that sends every value change that happens through `onNext()`.
/// Can be used for direct 1:n communication between objects.
public class PublishSubject<Value> {

    private var subscribers = [Subscriber<Value>]()

    public init() {}

    /// Adds a subscriber to get value updates.
    /// Use the returned `Disposable` to remove the subscription.
    public func subscribeNext(_ next: @escaping (Value) -> Void) -> Disposable {
        let subscriber = Subscriber(next: next)
        subscribers.append(subscriber)
        return Disposer { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.subscribers.removeObject(subscriber)
        }
    }

    /// Sends every subscriber a new value.
    public func onNext(_ value: Value) {
        let subscribersCopy = subscribers
        subscribersCopy.forEach { $0.next(value) }
    }
}
