//
//  BackgroundTimer.swift
//  SecureAccessBLE_Tests
//
//  Created by on 17.03.20.
//  Copyright © 2020 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

public class BackgroundTimer {
    private var timeInterval: TimeInterval
    private let queue: DispatchQueue
    private var _timer: DispatchSourceTimer?
    private var timer: DispatchSourceTimer {
        if _timer == nil {
            let timer = DispatchSource.makeTimerSource(queue: queue)
            timer.schedule(deadline: .now() + timeInterval)
            timer.setEventHandler(handler: { [weak self] in
                self?.eventHandler?()
            })
            _timer = timer
        }
        return _timer!
    }

    init(timeInterval: TimeInterval, queue: DispatchQueue) {
        self.timeInterval = timeInterval
        self.queue = queue
    }

    var eventHandler: (() -> Void)?
    private enum State {
        case stopped
        case running
    }

    private var state: State = .stopped

    deinit {
//        timer.setEventHandler {}
//        timer.cancel()
    }

    /// :nodoc:
    public func start() {
        if state == .running {
            return
        }
        state = .running
        timer.resume()
    }

    /// :nodoc:
    public func stop() {
        if state == .stopped {
            return
        }
        state = .stopped
        timer.cancel()
    }
}
