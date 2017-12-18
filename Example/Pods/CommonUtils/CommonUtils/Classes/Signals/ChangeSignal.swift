//
//  ChangeSignal.swift
//  CommonUtils
//
//  Created on 01.09.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

/// A signal that sends out updates to its current change.
/// On subscribe it sends out an initial action defined by `ChangeType.initialWithState(_:)`.
/// Can be used to differentiate between the initial subscription and following updates.
public class ChangeSignal<Change: ChangeType> {

    /// The current state of the signal's change
    public var state: Change.State {
        return changeSubject.state
    }

    private let changeSubject: ChangeSubject<Change>

    public init(changeSubject: ChangeSubject<Change>) {
        self.changeSubject = changeSubject
    }

    /// Adds a subscriber to every update of the current change.
    /// Sends the current change on subscribe.
    /// Use the returned `Disposable` to remove the subscription.
    public func subscribe(_ next: @escaping (Change) -> Void) -> Disposable {
        return changeSubject.subscribeNext(next)
    }
}

public extension ChangeSubject {

    /// Converts this `ChangeSubject` to a `ChangeSignal`.
    func asSignal() -> ChangeSignal<Change> {
        return ChangeSignal(changeSubject: self)
    }
}
