//
//  Disposing.swift
//  CommonUtils
//
//  Created on 30.05.17.
//  Copyright © 2018 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

/// Declares the methods every `Disposable` needs to implement
public protocol Disposable: AnyObject {
    /// Ends the current subscription
    func dispose()
}

/// Disposes multiple `Disposable`s at the same time via `dispose` or on deinit
public class DisposeBag: Disposable {
    private var disposables = [Disposable]()

    public init() {}

    /// Adds a disposable to this bag
    public func add(disposable: Disposable) {
        disposables.append(disposable)
    }

    /// Diposes all added `Disposable`s
    public func dispose() {
        disposables.forEach { $0.dispose() }
    }

    deinit {
        dispose()
    }
}

/// An extension to make it convenient to add `Disposable`s to a `DisposeBag`
public extension Disposable {
    /// Adds this `Disposable` to the given `DisposeBag`
    func disposed(by bag: DisposeBag) {
        bag.add(disposable: self)
    }
}

/// A wrapper around a dispose action
class Disposer: Disposable {
    private let disposeAction: () -> Void

    /// Initializes a disposer with a dispose action to wrap
    init(_ dispose: @escaping () -> Void) {
        disposeAction = dispose
    }

    /// Calls the dispose action
    public func dispose() {
        disposeAction()
    }
}
