//
//  DataConnectionChange.swift
//  SecureAccessBLE
//
//  Created by Torsten Lehmann on 17.08.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation
import CommonUtils

struct DataConnectionChange: ChangeType {

    let state: State
    let action: Action

    static func initialWithState(_ state: State) -> DataConnectionChange {
        return DataConnectionChange(state: state, action: .initial)
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
        case disconnected(sorcID: SorcID)
    }
}

extension DataConnectionChange: Equatable {

    static func ==(lhs: DataConnectionChange, rhs: DataConnectionChange) -> Bool {
        return lhs.state == rhs.state
            && lhs.action == rhs.action
    }
}

extension DataConnectionChange.State: Equatable {

    static func ==(lhs: DataConnectionChange.State,
                   rhs: DataConnectionChange.State) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected): return true
        case let (.connecting(lSorcID), .connecting(rSorcID)) where lSorcID == rSorcID: return true
        case let (.connected(lSorcID), .connected(rSorcID)) where lSorcID == rSorcID: return true
        default: return false
        }
    }
}

extension DataConnectionChange.Action: Equatable {

    static func ==(lhs: DataConnectionChange.Action,
                   rhs: DataConnectionChange.Action) -> Bool {
        switch (lhs, rhs) {
        case (.initial, .initial): return true
        case let (.connect(lSorcID), .connect(rSorcID)) where lSorcID == rSorcID: return true
        case let (.connectionEstablished(lSorcID), .connectionEstablished(rSorcID)) where lSorcID == rSorcID:
            return true
        case let (.connectingFailed(lSorcID), .connectingFailed(rSorcID)) where lSorcID == rSorcID: return true
        case (.disconnect, .disconnect): return true
        case let (.disconnected(lSorcID), .disconnected(rSorcID)) where lSorcID == rSorcID: return true
        default: return false
        }
    }
}
