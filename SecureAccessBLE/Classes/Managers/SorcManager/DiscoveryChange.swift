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
    /// The state a `DiscoveryChange` can be in
    public let state: State
    /// The action which led to the state change
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
    /// The state a `DiscoveryChange` can be in
    public struct State: Equatable {
        /// List of currently discovered sorcs
        public let discoveredSorcs: SorcInfos
        /// Flag notifying if discovery is enabled or not
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
    /// Action which led to a discovery change
    public enum Action: Equatable {
        /// Initial action (sent automatically on `subscribe`)
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

        /// Discovery started
        case startDiscovery

        /// Discovery stopped
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

/// Container for sorc infos
public struct SorcInfos: Equatable {
    private var sorcInfoByID: [SorcID: SorcInfo]

    public init(_ sorcInfoByID: [SorcID: SorcInfo] = [:]) {
        self.sorcInfoByID = sorcInfoByID
    }

    /// Subscript operator to get `SorcInfo` for given `SorcID`
    ///
    /// - Parameter sorcID: Sorc id
    public subscript(sorcID: SorcID) -> SorcInfo? {
        get {
            return sorcInfoByID[sorcID]
        }
        set {
            sorcInfoByID[sorcID] = newValue
        }
    }

    /// All sorc ids in the container
    public var sorcIDs: [SorcID] {
        return Array(sorcInfoByID.keys)
    }

    /// Returns true if the container is empty
    public var isEmpty: Bool {
        return sorcInfoByID.isEmpty
    }

    /// Checks if the container has the provided sorc id
    ///
    /// - Parameter sorcID: sorc id
    /// - Returns: `true` if provided `SorcID` is contained
    public func contains(_ sorcID: SorcID) -> Bool {
        return sorcInfoByID.keys.contains(sorcID)
    }

    public static func == (lhs: SorcInfos, rhs: SorcInfos) -> Bool {
        return lhs.sorcInfoByID == rhs.sorcInfoByID
    }
}
