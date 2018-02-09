//
//  DiscoveryChange.swift
//  SecureAccessBLE
//
//  Created on 09.08.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import CommonUtils

/// A change (state and last action) that describes the discovery transitions
public struct DiscoveryChange: ChangeType {
    public let state: State
    public let action: Action

    public static func initialWithState(_ state: State) -> DiscoveryChange {
        return DiscoveryChange(state: state, action: .initial)
    }

    public init(state: State, action: Action) {
        self.state = state
        self.action = action
    }
}

extension DiscoveryChange: Equatable {
    public static func == (lhs: DiscoveryChange, rhs: DiscoveryChange) -> Bool {
        return lhs.state == rhs.state
            && lhs.action == rhs.action
    }
}

extension DiscoveryChange {
    public struct State: Equatable {
        public let discoveredSorcs: SorcInfos
        public let discoveryIsEnabled: Bool

        public static func == (lhs: State, rhs: State) -> Bool {
            return lhs.discoveredSorcs == rhs.discoveredSorcs
                && lhs.discoveryIsEnabled == rhs.discoveryIsEnabled
        }

        public init(discoveredSorcs: SorcInfos, discoveryIsEnabled: Bool) {
            self.discoveredSorcs = discoveredSorcs
            self.discoveryIsEnabled = discoveryIsEnabled
        }

        public func withDiscoveryIsEnabled(_ enabled: Bool) -> State {
            return State(discoveredSorcs: discoveredSorcs, discoveryIsEnabled: enabled)
        }
    }
}

extension DiscoveryChange {
    public enum Action: Equatable {
        case initial

        /// The SORC was discovered
        case discovered(sorcID: SorcID)

        /// The SORC was discovered again or its info changed.
        ///
        /// Note: Can produce a lot of updates as a result of RSSI changes.
        /// Consider filtering this action out if you don't need it.
        case rediscovered(sorcID: SorcID)

        /// Discovered SORCs were not discovered recently and hence considered lost
        case lost(sorcIDs: Set<SorcID>)

        /// The disconnect was triggered manually
        case disconnect(sorcID: SorcID)

        /// The SORC was disconnected or disconnected on its own
        case disconnected(sorcID: SorcID)

        /// Discovered SORCs were cleared
        case reset

        case startDiscovery

        case stopDiscovery

        public static func == (lhs: Action, rhs: Action) -> Bool {
            switch (lhs, rhs) {
            case (.initial, .initial): return true
            case let (.discovered(lSorcID), .discovered(rSorcID)) where lSorcID == rSorcID: return true
            case let (.rediscovered(lSorcID), .rediscovered(rSorcID)) where lSorcID == rSorcID: return true
            case let (.lost(lSorcIDs), .lost(rSorcIDs)) where lSorcIDs == rSorcIDs: return true
            case let (.disconnect(lSorcID), .disconnect(rSorcID)) where lSorcID == rSorcID: return true
            case let (.disconnected(lSorcID), .disconnected(rSorcID)) where lSorcID == rSorcID: return true
            case (.reset, .reset): return true
            case (.startDiscovery, .startDiscovery): return true
            case (.stopDiscovery, .stopDiscovery): return true
            default: return false
            }
        }
    }
}

public struct SorcInfos: Equatable {
    private var sorcInfoByID: [SorcID: SorcInfo]

    public init(_ sorcInfoByID: [SorcID: SorcInfo] = [:]) {
        self.sorcInfoByID = sorcInfoByID
    }

    public subscript(sorcID: SorcID) -> SorcInfo? {
        get {
            return sorcInfoByID[sorcID]
        }
        set {
            sorcInfoByID[sorcID] = newValue
        }
    }

    public var sorcIDs: [SorcID] {
        return Array(sorcInfoByID.keys)
    }

    public var isEmpty: Bool {
        return sorcInfoByID.isEmpty
    }

    public func contains(_ sorcID: SorcID) -> Bool {
        return sorcInfoByID.keys.contains(sorcID)
    }

    public static func == (lhs: SorcInfos, rhs: SorcInfos) -> Bool {
        return lhs.sorcInfoByID == rhs.sorcInfoByID
    }
}
