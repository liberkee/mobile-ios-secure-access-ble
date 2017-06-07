//
//  ConnectionChange.swift
//  SecureAccessBLE
//
//  Created by Torsten Lehmann on 07.06.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

public struct ConnectionChange {

    // Possible state transitions (other transitions have no observable result, i.e. <no change>)
    //                -initial->               (disconnected)
    // (disconnected) -connect->               (connecting)
    // (disconnected) -disconnect->            <no change>
    // (connecting)   -connect->               <no change>
    // (connecting)   -disconnect->            (disconnected)
    // (connecting)   -connectionEstablished-> (connected)
    // (connecting)   -connectingFailed->      (disconnected)
    // (connected)    -connect->               <no change>
    // (connected)    -disconnect->            (disconnected)
    // (connected)    -connectionLost->        (disconnected)

    public enum State {
        case disconnected
        case connecting(sorcId: String)
        case connected(sorcId: String)
    }

    public enum Action {
        // external
        case connect
        case disconnect
        // internal
        case initial
        case connectionEstablished(sorcId: String, rssi: Int)
        case connectingFailed(error: ConnectingFailedError, sorcId: String, rssi: Int)
        case connectionLost(error: ConnectionLostError)
    }

    public let state: State
    public let action: Action

    public init(state: State, action: Action) {
        self.state = state
        self.action = action
    }
}

public enum ConnectingFailedError {
    case blobOutdated
    case unknown
}

public enum ConnectionLostError {
    case heartbeatTimedOut
    case unknown
}
