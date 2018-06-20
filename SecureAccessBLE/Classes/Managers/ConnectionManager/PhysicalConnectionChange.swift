//
//  PhysicalConnectionChange.swift
//  SecureAccessBLE
//
//  Created on 18.08.17.
//  Copyright © 2018 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

struct PhysicalConnectionChange: ChangeType {
    let state: State
    let action: Action

    static func initialWithState(_ state: State) -> PhysicalConnectionChange {
        return PhysicalConnectionChange(state: state, action: .initial)
    }

    enum State {
        case disconnected
        case connecting(sorcID: SorcID)
        case connected(sorcID: SorcID)
    }

    enum Action {
        case initial
        case connect(sorcID: SorcID)
        case connectionEstablished(sorcID: SorcID)
        case connectingFailed(sorcID: SorcID)
        case disconnect(sorcID: SorcID)
        case connectionLost(sorcID: SorcID)
    }
}

extension PhysicalConnectionChange: Equatable {
    static func == (lhs: PhysicalConnectionChange, rhs: PhysicalConnectionChange) -> Bool {
        return lhs.state == rhs.state
            && lhs.action == rhs.action
    }
}

extension PhysicalConnectionChange.State: Equatable {
    static func == (lhs: PhysicalConnectionChange.State,
                    rhs: PhysicalConnectionChange.State) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected): return true
        case let (.connecting(lSorcID), .connecting(rSorcID)) where lSorcID == rSorcID: return true
        case let (.connected(lSorcID), .connected(rSorcID)) where lSorcID == rSorcID: return true
        default: return false
        }
    }
}

extension PhysicalConnectionChange.Action: Equatable {
    static func == (lhs: PhysicalConnectionChange.Action,
                    rhs: PhysicalConnectionChange.Action) -> Bool {
        switch (lhs, rhs) {
        case (.initial, .initial): return true
        case let (.connect(lSorcID), .connect(rSorcID)) where lSorcID == rSorcID: return true
        case let (.connectionEstablished(lSorcID), .connectionEstablished(rSorcID)) where lSorcID == rSorcID:
            return true
        case let (.connectingFailed(lSorcID), .connectingFailed(rSorcID)) where lSorcID == rSorcID: return true
        case (.disconnect, .disconnect): return true
        case let (.connectionLost(lSorcID), .connectionLost(rSorcID)) where lSorcID == rSorcID: return true
        default: return false
        }
    }
}
