// TACSConnectionChangeFactory.swift
// TACSTests

// Created on 03.05.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.

import Foundation
@testable import TACS

class TACSConnectionChangeFactory {
    static func leaseDataErrorChange() -> ConnectionChange {
        let state = ConnectionChange.State.disconnected
        let action = ConnectionChange.Action.connectingFailedDataMissing
        let change = ConnectionChange(state: state, action: action)
        return change
    }
}
