// RepeatingBackgroundTimer.swift
// SecureAccessBLE

// Created on 20.05.19.
// Copyright © 2019 Huf Secure Mobile GmbH. All rights reserved.

import Foundation

/// :nodoc:
// A custom timer implementation influenced by https://medium.com/over-engineering/a-background-repeating-timer-in-swift-412cecfd2ef9
// RepeatingTimer mimics the API of DispatchSourceTimer but in a way that prevents
// crashes that occur from calling resume multiple times on a timer that is
// already resumed (noted by https://github.com/SiftScience/sift-ios/issues/52
public class RepeatingBackgroundTimer {
    private var timeInterval: TimeInterval
    private let queue: DispatchQueue

    /// :nodoc:
    public static func scheduledTimer(timeInterval: TimeInterval,
                                      queue: DispatchQueue,
                                      handler: @escaping () -> Void) -> RepeatingBackgroundTimer {
        let timer = RepeatingBackgroundTimer(timeInterval: timeInterval, queue: queue)
        timer.eventHandler = handler
        timer.resume()
        return timer
    }

    init(timeInterval: TimeInterval, queue: DispatchQueue) {
        self.timeInterval = timeInterval
        self.queue = queue
    }

    func start() {
        suspend()
        resume()
    }

    func restart(timeInterval: TimeInterval) {
        suspend()
        self.timeInterval = timeInterval
        resume()
    }

    private lazy var timer: DispatchSourceTimer = {
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now() + self.timeInterval, repeating: self.timeInterval)
        t.setEventHandler(handler: { [weak self] in
            self?.eventHandler?()
        })
        return t
    }()

    var eventHandler: (() -> Void)?

    private enum State {
        case suspended
        case resumed
    }

    private var state: State = .suspended

    deinit {
        timer.setEventHandler {}
        timer.cancel()
        /*
         If the timer is suspended, calling cancel without resuming
         triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
         */
        resume()
        eventHandler = nil
    }

    /// :nodoc:
    public func resume() {
        if state == .resumed {
            return
        }
        state = .resumed
        timer.resume()
    }

    /// :nodoc:
    public func suspend() {
        if state == .suspended {
            return
        }
        state = .suspended
        timer.suspend()
    }
}
