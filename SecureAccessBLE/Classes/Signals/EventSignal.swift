//
//  EventSignal.swift
//  CommonUtils
//
//  Created on 01.09.17.
//  Copyright © 2018 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

/// A signal that sends events
public class EventSignal<Event> {
    private let publishSubject: PublishSubject<Event>

    public init(publishSubject: PublishSubject<Event>) {
        self.publishSubject = publishSubject
    }

    /// Adds a subscriber to get event updates.
    /// Use the returned `Disposable` to remove the subscription.
    public func subscribe(_ next: @escaping (Event) -> Void) -> Disposable {
        return publishSubject.subscribeNext(next)
    }
}

public extension PublishSubject {
    /// Converts this `PublishSubject` to a `EventSignal`.
    func asSignal() -> EventSignal<Value> {
        return EventSignal(publishSubject: self)
    }
}
