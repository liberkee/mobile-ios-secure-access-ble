//
//  SorcConnectionManagerExtensions.swift
//  SecureAccessBLE
//
//  Copyright © 2016 Huf Secure Mobile. All rights reserved.
//

import CoreBluetooth
import CommonUtils

extension SorcConnectionManager {

    typealias CreateTimer = (@escaping () -> Void) -> Timer

    struct DiscoveryChange: ChangeType {

        let state: Set<SorcID>
        let action: Action

        static func initialWithState(_ state: Set<SorcID>) -> DiscoveryChange {
            return DiscoveryChange(state: state, action: .initial)
        }

        enum Action {
            case initial
            case sorcDiscovered(SorcID)
            case sorcsLost(Set<SorcID>)
            case disconnectSorc(SorcID)
            case sorcDisconnected(SorcID)
            case sorcsReset
        }
    }

    struct ConnectionChange: ChangeType {

        let state: State
        let action: Action

        static func initialWithState(_ state: State) -> ConnectionChange {
            return ConnectionChange(state: state, action: .initial)
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
            case disconnect
            case disconnected(sorcID: SorcID)
        }
    }
}

extension SorcConnectionManager.DiscoveryChange: Equatable {

    static func ==(lhs: SorcConnectionManager.DiscoveryChange, rhs: SorcConnectionManager.DiscoveryChange) -> Bool {
        return lhs.state == rhs.state
            && lhs.action == rhs.action
    }
}

extension SorcConnectionManager.DiscoveryChange.Action: Equatable {

    static func ==(lhs: SorcConnectionManager.DiscoveryChange.Action,
                   rhs: SorcConnectionManager.DiscoveryChange.Action) -> Bool {
        switch (lhs, rhs) {
        case (.initial, .initial): return true
        case let (.sorcDiscovered(lSorcID), .sorcDiscovered(rSorcID)) where lSorcID == rSorcID: return true
        case let (.sorcsLost(lSorcIDs), .sorcsLost(rSorcIDs)) where lSorcIDs == rSorcIDs: return true
        case let (.disconnectSorc(lSorcID), .disconnectSorc(rSorcID)) where lSorcID == rSorcID: return true
        case let (.sorcDisconnected(lSorcID), .sorcDisconnected(rSorcID)) where lSorcID == rSorcID: return true
        case (.sorcsReset, .sorcsReset): return true
        default: return false
        }
    }
}

extension SorcConnectionManager.ConnectionChange: Equatable {

    static func ==(lhs: SorcConnectionManager.ConnectionChange, rhs: SorcConnectionManager.ConnectionChange) -> Bool {
        return lhs.state == rhs.state
            && lhs.action == rhs.action
    }
}

extension SorcConnectionManager.ConnectionChange.State: Equatable {

    static func ==(lhs: SorcConnectionManager.ConnectionChange.State,
                   rhs: SorcConnectionManager.ConnectionChange.State) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected): return true
        case let (.connecting(lSorcID), .connecting(rSorcID)) where lSorcID == rSorcID: return true
        case let (.connected(lSorcID), .connected(rSorcID)) where lSorcID == rSorcID: return true
        default: return false
        }
    }
}

extension SorcConnectionManager.ConnectionChange.Action: Equatable {

    static func ==(lhs: SorcConnectionManager.ConnectionChange.Action,
                   rhs: SorcConnectionManager.ConnectionChange.Action) -> Bool {
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

// MARK: - CBCentralManagerDelegate

extension SorcConnectionManager: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        centralManagerDidUpdateState_(central as CBCentralManagerType)
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {

        centralManager_(central as CBCentralManagerType, didDiscover: peripheral as CBPeripheralType, advertisementData: advertisementData, rssi: RSSI)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        centralManager_(central as CBCentralManagerType, didConnect: peripheral as CBPeripheralType)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        centralManager_(central as CBCentralManagerType, didFailToConnect: peripheral as CBPeripheralType, error: error)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        centralManager_(central as CBCentralManagerType, didDisconnectPeripheral: peripheral as CBPeripheralType,
                        error: error)
    }
}

// MARK: - CBPeripheralDelegate

extension SorcConnectionManager: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        peripheral_(peripheral as CBPeripheralType, didDiscoverServices: error)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        peripheral_(peripheral as CBPeripheralType, didDiscoverCharacteristicsFor: service as CBServiceType,
                    error: error)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        peripheral_(peripheral, didUpdateValueFor: characteristic as CBCharacteristicType, error: error)
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        peripheral_(peripheral as CBPeripheralType, didWriteValueFor: characteristic, error: error)
    }
}
