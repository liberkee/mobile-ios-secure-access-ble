//
//  PhysicalConnectionChange.swift
//  SecureAccessBLE
//
//  Created on 18.08.17.
//  Copyright © 2018 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

struct PhysicalConnectionChange: ChangeType, Equatable {
    let state: State
    let action: Action

    static func initialWithState(_ state: State) -> PhysicalConnectionChange {
        return PhysicalConnectionChange(state: state, action: .initial)
    }

    enum State: Equatable {
        case disconnected
        case connecting(sorcID: SorcID)
        case connected(sorcID: SorcID)
    }

    enum Action: Equatable {
        case initial
        case connect(sorcID: SorcID)
        case connectionEstablished(sorcID: SorcID, mtuSize: Int)
        case connectingFailed(sorcID: SorcID)
        case disconnect(sorcID: SorcID)
        case connectionLost(sorcID: SorcID)
    }
}
