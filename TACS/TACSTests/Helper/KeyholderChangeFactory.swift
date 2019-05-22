// KeyholderChangeFactory.swift
// TACSTests

// Created on 21.05.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.

import Foundation
@testable import TACS

class KeyholderStatusChangeFactory {
    static func failedIdMissingChange() -> KeyholderStatusChange {
        return KeyholderStatusChange(state: .stopped, action: .failed(.keyholderIdMissing))
    }
}
