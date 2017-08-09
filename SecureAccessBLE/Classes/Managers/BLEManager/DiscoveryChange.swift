//
//  DiscoveryChange.swift
//  SecureAccessBLE
//
//  Created by Torsten Lehmann on 09.08.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation
import CommonUtils

/// A change (state and last action) that describes the discovery transitions
public struct DiscoveryChange: ChangeType {

    public let state: Set<SorcID>
    public let action: Action

    public static func initialWithState(_ state: Set<SorcID>) -> DiscoveryChange {
        return DiscoveryChange(state: state, action: .initial)
    }

    public enum Action {
        case initial

        /// The SORC was discovered
        case discovered(sorcID: SorcID)

        /// Discovered SORCs were not discovered recently and hence considered lost
        case lost(sorcIDs: Set<SorcID>)

        /// The disconnect was triggered manually
        case disconnect(sorcID: SorcID)

        /// The SORC was disconnected or disconnected on its own
        case disconnected(sorcID: SorcID)

        /// Discovered SORCs were cleared
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
