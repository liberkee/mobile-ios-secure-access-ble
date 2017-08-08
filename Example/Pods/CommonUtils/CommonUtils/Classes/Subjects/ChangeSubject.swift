//
//  ChangeSubject.swift
//  CommonUtils
//
//  Created by Torsten Lehmann on 30.05.17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

/// A protocol describing a type that represents a state transition with `state` as the current state
/// and `action` as the action that led to this state. Used together with `ChangeSubject`.
public protocol ChangeType {
    associatedtype State
    associatedtype Action

    var state: State { get }
    var action: Action { get }

    /// Returns a change value with given state and initial action
    static func initialWithState(_ state: State) -> Self
}

/// A subject that keeps the current state and sends it on subscribe with an initial action defined by
/// `ChangeType.initalWithState(_:)`. Futhermore it sends the current change provided by every `onNext(_:) call.
/// Can be used to differentiate between the initial subscribtion and following updates.
/// Can be used for direct 1:n communication between objects.
public class ChangeSubject<Change: ChangeType> {

    /// The current state of the subject
    public private(set) var state: Change.State
    private var subscribers = [Subscriber<Change>]()

    /// The initializer for this subject, an initial state is mandatory
    public init(state: Change.State) {
        self.state = state
    }

    /// Adds a subscriber to every change of the current value.
    /// Sends the current value on subscribe.
    /// Use the returned `Disposable` to remove the subscription.
    public func subscribeNext(_ next: @escaping (Change) -> Void) -> Disposable {
        let subscriber = Subscriber(next: next)
        subscribers.append(subscriber)
        subscriber.next(Change.initialWithState(state))
        return Disposer { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.subscribers.removeObject(subscriber)
        }
    }

    /// Sends every subscriber a new change.
    public func onNext(_ change: Change) {
        state = change.state
        let subscribersCopy = subscribers
        subscribersCopy.forEach { $0.next(change) }
    }
}
