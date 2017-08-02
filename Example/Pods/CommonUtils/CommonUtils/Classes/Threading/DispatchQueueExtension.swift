//
//  DispatchQueueExtension.swift
//  CommonUtils
//
//  Created by Oleg Langer on 11.07.17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

extension DispatchQueue {

    /// Dispatch on main queue peventing deadlock
    public class func mainSyncSafe<T>(execute work: () -> T) -> T {
        if Thread.current.isMainThread {
            return work()
        } else {
            // work dispatched sync to the main queue always runs on the main thread
            return DispatchQueue.main.sync(execute: work)
        }
    }
}
