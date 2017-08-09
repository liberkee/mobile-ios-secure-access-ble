//
//  DiscoveryChange.swift
//  SecureAccessBLE
//
//  Created by Torsten Lehmann on 09.08.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation
import CommonUtils

public struct DiscoveryChange: ChangeType {

    public let state: Set<SorcID>
    public let action: Action

    public static func initialWithState(_ state: Set<SorcID>) -> DiscoveryChange {
        return DiscoveryChange(state: state, action: .initial)
    }

    public enum Action {
        case initial
        case discovered(sorcID: SorcID)
        case lost(sorcIDs: Set<SorcID>)
        case disconnect(sorcID: SorcID)
        case disconnected(sorcID: SorcID)
        case reset
    }
}

extension DiscoveryChange: Equatable {

    public static func ==(lhs: DiscoveryChange, rhs: DiscoveryChange) -> Bool {
        return lhs.state == rhs.state
            && lhs.action == rhs.action
    }
}

extension DiscoveryChange.Action: Equatable {

    public static func ==(lhs: DiscoveryChange.Action, rhs: DiscoveryChange.Action) -> Bool {
        switch (lhs, rhs) {
        case (.initial, .initial): return true
        case let (.discovered(lSorcID), .discovered(rSorcID)) where lSorcID == rSorcID: return true
        case let (.lost(lSorcIDs), .lost(rSorcIDs)) where lSorcIDs == rSorcIDs: return true
        case let (.disconnect(lSorcID), .disconnect(rSorcID)) where lSorcID == rSorcID: return true
        case let (.disconnected(lSorcID), .disconnected(rSorcID)) where lSorcID == rSorcID: return true
        case (.reset, .reset): return true
        default: return false
        }
    }
}
