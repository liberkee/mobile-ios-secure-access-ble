//
//  StateSignal.swift
//  CommonUtils
//
//  Created on 01.09.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

/// A signal that sends out updates to its current state
public class StateSignal<State> {
    // The current state of the signal
    public var state: State {
        return behaviorSubject.value
    }

    private let behaviorSubject: BehaviorSubject<State>

    public init(behaviorSubject: BehaviorSubject<State>) {
        self.behaviorSubject = behaviorSubject
    }

    /// Adds a subscriber to every change of the current state.
    /// Sends the current state on subscribe.
    /// Use the returned `Disposable` to remove the subscription.
    public func subscribe(_ next: @escaping (State) -> Void) -> Disposable {
        return behaviorSubject.subscribeNext(next)
    }
}

public extension BehaviorSubject {
    /// Converts this `BehaviorSubject` to a `StateSignal`.
    func asSignal() -> StateSignal<Value> {
        return StateSignal(behaviorSubject: self)
    }
}
