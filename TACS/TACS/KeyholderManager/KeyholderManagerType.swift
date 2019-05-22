// KeyholderManagerType.swift
// TACS

// Created on 03.05.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.

import Foundation
import SecureAccessBLE

public protocol KeyholderManagerType {
    func requestStatus(timeout: TimeInterval)
    var keyholderChange: ChangeSignal<KeyholderStatusChange> { get }
}

extension KeyholderManagerType {
    func requestStatus() {
        requestStatus(timeout: 5.0)
    }
}
