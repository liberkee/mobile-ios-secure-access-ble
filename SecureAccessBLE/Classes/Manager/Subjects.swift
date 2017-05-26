//
//  Subjects.swift
//  SecureAccessBLE
//
//  Created by Torsten Lehmann on 24.05.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

public protocol Disposable: class {
    func dispose()
}

class Disposer: Disposable {

    private let disposeAction: () -> Void

    init(_ dispose: @escaping () -> Void) {
        disposeAction = dispose
    }

    public func dispose() {
        disposeAction()
    }
}

public class DisposeBag {

    private var disposables = [Disposable]()

    public init() {}

    func add(disposable: Disposable) {
        disposables.append(disposable)
    }

    deinit {
        disposables.forEach { $0.dispose() }
    }
}

public extension Disposable {
    func disposed(by bag: DisposeBag) {
        bag.add(disposable: self)
    }
}

class Subscriber<Value> {

    let next: (Value) -> Void

    init(next: @escaping (Value) -> Void) {
        self.next = next
    }
}

public class BehaviorSubject<Value> {

    private var value: Value
    private var subscribers = [Subscriber<Value>]()

    public init(value: Value) {
        self.value = value
    }

    public func subscribeNext(_ next: @escaping (Value) -> Void) -> Disposable {
        let subscriber = Subscriber(next: next)
        subscribers.append(subscriber)
        subscriber.next(value)
        return Disposer { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.subscribers.removeObject(subscriber)
        }
    }

    public func onNext(_ value: Value) {
        self.value = value
        let subscribersCopy = subscribers
        subscribersCopy.forEach { $0.next(value) }
    }
}

public class PublishSubject<Value> {

    private var subscribers = [Subscriber<Value>]()

    public func subscribeNext(_ next: @escaping (Value) -> Void) -> Disposable {
        let subscriber = Subscriber(next: next)
        subscribers.append(subscriber)
        return Disposer { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.subscribers.removeObject(subscriber)
        }
    }

    public func onNext(_ value: Value) {
        let subscribersCopy = subscribers
        subscribersCopy.forEach { $0.next(value) }
    }
}
