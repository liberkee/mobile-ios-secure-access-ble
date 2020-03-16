//
//  DiscoveryChange.swift
//  SecureAccessBLE
//
//  Created on 09.08.17.
//  Copyright © 2018 Huf Secure Mobile GmbH. All rights reserved.
//

/// A change (state and last action) that describes the discovery transitions
public struct DiscoveryChange: ChangeType {
    /// The state a `DiscoveryChange` can be in
    public let state: State

    /// The action which led to the state change
    public let action: Action

    /// :nodoc:
    public static func initialWithState(_ state: State) -> DiscoveryChange {
        return DiscoveryChange(state: state, action: .initial)
    }

    /// :nodoc:
    public init(state: State, action: Action) {
        self.state = state
        self.action = action
    }
}

extension DiscoveryChange: Equatable {}

extension DiscoveryChange {
    /// The state a `DiscoveryChange` can be in
    public struct State: Equatable {
        /// A list of currently discovered SORCs
        public let discoveredSorcs: SorcInfos

        /// A flag thats indicates whether discovery is enabled or not
        public let discoveryIsEnabled: Bool

        public let requestedSorc: SorcID?

        func withDiscoveryIsEnabled(_ enabled: Bool) -> State {
            return State(discoveredSorcs: discoveredSorcs, discoveryIsEnabled: enabled)
        }

        public init(discoveredSorcs: SorcInfos, discoveryIsEnabled: Bool, requestedSorc: SorcID? = nil) {
            self.discoveredSorcs = discoveredSorcs
            self.discoveryIsEnabled = discoveryIsEnabled
            self.requestedSorc = requestedSorc
        }
    }
}

extension DiscoveryChange {
    /// An action which led to a discovery change
    public enum Action: Equatable {
        /// Initial action (sent automatically on `subscribe`)
        case initial

        case discoveryStarted(sorcID: SorcID)

        case discoveryFailed

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
    }
}

/// Container for SORC infos
public struct SorcInfos: Equatable {
    private var sorcInfoByID: [SorcID: SorcInfo]

    /// All SORC IDs in the container
    public var sorcIDs: [SorcID] {
        return Array(sorcInfoByID.keys)
    }

    /// Returns `true` if the container is empty
    public var isEmpty: Bool {
        return sorcInfoByID.isEmpty
    }

    /// Checks if the container has the provided SORC ID
    ///
    /// - Parameter sorcID: sorc id
    /// - Returns: `true` if provided `SorcID` is contained
    public func contains(_ sorcID: SorcID) -> Bool {
        return sorcInfoByID.keys.contains(sorcID)
    }

    /// Subscript operator to get `SorcInfo` for given `SorcID`
    ///
    /// - Parameter sorcID: The SORC ID
    public subscript(sorcID: SorcID) -> SorcInfo? {
        get {
            return sorcInfoByID[sorcID]
        }
        set {
            sorcInfoByID[sorcID] = newValue
        }
    }

    public init(_ sorcInfoByID: [SorcID: SorcInfo] = [:]) {
        self.sorcInfoByID = sorcInfoByID
    }
}
