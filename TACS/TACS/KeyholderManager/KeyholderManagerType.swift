// KeyholderManagerType.swift
// TACS

// Created on 03.05.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.

import Foundation
import SecureAccessBLE

public protocol KeyholderManagerType {
    /// Keyholder change which can be used to retrieve keyholder status
    var keyholderChange: ChangeSignal<KeyholderStatusChange> { get }
    /// Requests keyholder status and notifies changes via `keyholderChange`
    ///
    /// - Parameter timeout: Interval which defines discovery timeout. If the keyholder is not discovered during given timeout,
    /// appropriate error change will be notified via `keyholderChange`.
    func requestStatus(timeout: TimeInterval)
}

public extension KeyholderManagerType {
    /// Helper function which requests status with default timeout of 5 seconds.
    func requestStatus() {
        requestStatus(timeout: 5.0)
    }
}
