//
//  BLEScanner.swift
//  BLE
//
//  Created by Ke Song on 21.06.16.
//  Copyright © 2016 Huf Secure Mobile. All rights reserved.
//

import CoreBluetooth
import CommonUtils

extension BLEScanner {

    struct DiscoveryChange {

        let state: Set<SorcID>
        let action: Action

        enum Action {
            case initial
            case sorcDiscovered(SorcID)
            case sorcsLost(Set<SorcID>)
            case sorcDisconnected(SorcID)
            case sorcsReset
        }
    }

    struct ConnectionChange {

        let state: State
        let action: Action

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

/**
 *  Definition for SID object
 */
private struct SID: Hashable, Equatable {

    let sidID: String
    var peripheral: CBPeripheralType?
    let discoveryDate: Date
    let rssi: Int

    var hashValue: Int {
        return sidID.hashValue
    }

    static func == (lhs: SID, rhs: SID) -> Bool {
        if (lhs.peripheral?.identifier != rhs.peripheral?.identifier) || (lhs.sidID != rhs.sidID) {
            return false
        }

        return true
    }
}

extension CBManagerState {

    var description: String {
        switch self {
        case .unknown: return "Unknown"
        case .resetting: return "Resetting"
        case .unsupported: return "Unsupported"
        case .unauthorized: return "Unauthorized"
        case .poweredOff: return "PoweredOff"
        case .poweredOn: return "PoweredOn"
        }
    }
}

/// BLEScanner implaments the secure BLE session between mobile devices and SID. The communication manager can only send / receive
/// messages over a secure BLE connection, i.e. a valid session context must exist.
class BLEScanner: NSObject, DataTransfer {

    typealias CreateTimer = (@escaping () -> Void) -> Timer

    /// delegate for message tranfer
    weak var delegate: DataTransferDelegate?

    /// central mananger object defined in Core Bluetooth
    var centralManager: CBCentralManagerType!

    let systemClock: SystemClockType

    let isPoweredOn: BehaviorSubject<Bool>
    let discoveryChange = BehaviorSubject(value: DiscoveryChange(state: Set<SorcID>(), action: .initial))

    let connectionChange = BehaviorSubject(value: ConnectionChange(state: .disconnected, action: .initial))

    fileprivate let deviceId = "EF82084D-BFAD-4ABE-90EE-2552C20C5765"
    fileprivate let serviceId = "d1cf0603-b501-4569-a4b9-e47ad3f628a5"
    fileprivate let notifyCharacteristicId = "d1d7a6b6-457e-458a-b237-a9df99b3d98b"
    fileprivate let writeCharacteristicId = "c8e58f23-9417-41c6-97a8-70f6b2c8cab9"

    fileprivate var writeCharacteristic: CBCharacteristicType?
    fileprivate var notifyCharacteristic: CBCharacteristicType?

    /// Timer to remove outdated discovered SORCs
    fileprivate var filterTimer: Timer?

    /// The duration a SORC is considered outdated if last discovery date is longer ago than this duration
    private let sorcOutdatedDurationSeconds: Double = 5

    /// The SORCs that were discovered and were not removed by the filterTimer
    fileprivate var discoveredSorcs = Set<SID>()

    fileprivate var connectedSid: SID? {
        if case let .connected(sorcId) = connectionState {
            return discoveredSorcs.first { $0.sidID == sorcId }
        }
        return nil
    }

    fileprivate var connectionState: ConnectionChange.State {
        return connectionChange.value.state
    }

    required init(centralManager: CBCentralManagerType, systemClock: SystemClockType,
                  createTimer: CreateTimer) {

        self.systemClock = systemClock
        isPoweredOn = BehaviorSubject(value: centralManager.state == .poweredOn)
        super.init()

        self.centralManager = centralManager
        centralManager.delegate = self

        filterTimer = createTimer(removeOutdatedSorcs)
    }

    convenience override init() {
        let centralManager = CBCentralManager(delegate: nil, queue: nil,
                                              options: [CBPeripheralManagerOptionShowPowerAlertKey: 0])
        let systemClock = SystemClock()

        let createTimer: CreateTimer = { block in
            /// The interval a timer is triggered to remove outdated discovered SORCs
            let removeOutdatedSorcsTimerIntervalSeconds: Double = 2
            return Timer(timeInterval: removeOutdatedSorcsTimerIntervalSeconds, repeats: true, block: { _ in block() })
        }

        self.init(
            centralManager: centralManager,
            systemClock: systemClock,
            createTimer: createTimer
        )
    }

    deinit {
        disconnect()
        filterTimer?.invalidate()
    }

    /// If a connection to an undiscovered SORC is tried it fails silently.
    func connectToSorc(_ sorcID: SorcID) {
        guard let peripheral = peripheralMatchingSorcID(sorcID) else {
            print("BLEScanner: Try to connect to SORC that is not discovered.")
            return
        }
        switch connectionState {
        case let .connecting(currentSorcID):
            if currentSorcID != sorcID {
                disconnect()
                connectionChange.onNext(.init(state: .connecting(sorcID: sorcID), action: .connect(sorcID: sorcID)))
            }
            centralManager.connect(peripheral, options: nil)
        case let .connected(currentSorcID):
            if currentSorcID != sorcID {
                disconnect()
                connectionChange.onNext(.init(state: .connecting(sorcID: sorcID), action: .connect(sorcID: sorcID)))
                centralManager.connect(peripheral, options: nil)
            }
        case .disconnected:
            connectionChange.onNext(.init(state: .connecting(sorcID: sorcID), action: .connect(sorcID: sorcID)))
            centralManager.connect(peripheral, options: nil)
        }
    }

    func disconnect() {
        disconnect(withAction: .disconnect)
    }

    /**
     Sending data to current connected peripheral

     - parameter data: NSData that will be sended to SID
     */
    func sendData(_ data: Data) {
        guard case let .connected(sorcID) = connectionState,
            let characteristic = writeCharacteristic,
            let peripheral = peripheralMatchingSorcID(sorcID) else { return }

        peripheral.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
    }

    // MARK: - Private methods

    fileprivate func disconnect(withAction action: ConnectionChange.Action) {
        switch connectionState {
        case let .connecting(sorcID), let .connected(sorcID):
            if let peripheral = peripheralMatchingSorcID(sorcID) {
                centralManager.cancelPeripheralConnection(peripheral)
            }
            writeCharacteristic = nil
            notifyCharacteristic = nil
            connectionChange.onNext(.init(state: .disconnected, action: action))
        case .disconnected: break
        }
    }

    fileprivate func startScan() {
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: 1])
    }

    private func removeOutdatedSorcs() {
        let outdatedSorcs = discoveredSorcs.filter { (sorc) -> Bool in
            let outdated = systemClock.timeIntervalSinceNow(for: sorc.discoveryDate) < -sorcOutdatedDurationSeconds
            return outdated && sorc.sidID != self.connectedSid?.sidID
        }
        if outdatedSorcs.count > 0 {
            for sorc in outdatedSorcs {
                discoveredSorcs.remove(sorc)
            }
            let outdatedSorcIDs = outdatedSorcs.map { $0.sidID }
            updateDiscoveryChange(action: .sorcsLost(Set(outdatedSorcIDs)))
        }
    }

    fileprivate func updateDiscoveredSorcsWithNewSorc(_ sorc: SID) {
        var sorcCopy = sorc
        if let connectedSid = connectedSid, sorcCopy.sidID == connectedSid.sidID {
            sorcCopy.peripheral = connectedSid.peripheral
        }
        let replacedSidID = discoveredSorcs.update(with: sorcCopy)
        if replacedSidID == nil {
            updateDiscoveryChange(action: .sorcDiscovered(sorc.sidID))
        }
    }

    fileprivate func resetDiscoveredSorcs() {
        discoveredSorcs = Set<SID>()
        updateDiscoveryChange(action: .sorcsReset)
    }

    fileprivate func updateDiscoveryChange(action: DiscoveryChange.Action) {
        let discoveredSorcIds = discoveredSorcs.map { $0.sidID }
        let change = DiscoveryChange(state: Set(discoveredSorcIds), action: action)
        discoveryChange.onNext(change)
    }

    fileprivate func sorcMatchingSorcID(_ sorcID: SorcID) -> SID? {
        return discoveredSorcs
            .filter { $0.sidID.lowercased() == sorcID.replacingOccurrences(of: "-", with: "").lowercased() }
            .first
    }

    fileprivate func peripheralMatchingSorcID(_ sorcID: SorcID) -> CBPeripheralType? {
        return sorcMatchingSorcID(sorcID)?.peripheral
    }
}

// MARK: - CBCentralManagerDelegate_

extension BLEScanner {

    func centralManagerDidUpdateState_(_ central: CBCentralManagerType) {
        consoleLog("BLEScanner Central updated state: \(central.state)")

        isPoweredOn.onNext(central.state == .poweredOn)
        if central.state == .poweredOn {
            startScan()
        } else {
            resetDiscoveredSorcs()
        }
    }

    func centralManager_(_: CBCentralManagerType, didDiscover peripheral: CBPeripheralType, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data else {
            return
        }
        let sidID = manufacturerData.toHexString()
        let sorc = SID(sidID: sidID, peripheral: peripheral, discoveryDate: systemClock.now(), rssi: RSSI.intValue)
        updateDiscoveredSorcsWithNewSorc(sorc)
    }

    func centralManager_(_: CBCentralManagerType, didConnect peripheral: CBPeripheralType) {
        consoleLog("Central connected to peripheral: \(peripheral.identifier.uuidString)")

        guard case let .connecting(sorcID) = connectionState,
            peripheralMatchingSorcID(sorcID)?.identifier == peripheral.identifier else { return }

        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: serviceId)])
    }

    func centralManager_(_: CBCentralManagerType, didFailToConnect peripheral: CBPeripheralType, error: Error?) {
        consoleLog("Central failed connecting to peripheral: \(error?.localizedDescription ?? "Unknown error")")

        guard case let .connecting(sorcID) = connectionState,
            peripheralMatchingSorcID(sorcID)?.identifier == peripheral.identifier else { return }

        connectionChange.onNext(.init(state: .disconnected, action: .connectingFailed(sorcID: sorcID)))
    }

    func centralManager_(_: CBCentralManagerType, didDisconnectPeripheral peripheral: CBPeripheralType, error _: Error?) {
        guard case let .connected(sorcID) = connectionState,
            let sorc = sorcMatchingSorcID(sorcID),
            sorc.peripheral?.identifier == peripheral.identifier else { return }

        discoveredSorcs.remove(sorc)
        updateDiscoveryChange(action: .sorcDisconnected(sorcID))
        connectionChange.onNext(.init(state: .disconnected, action: .disconnected(sorcID: sorcID)))
    }
}

// MARK: - CBPeripheralDelegate_

extension BLEScanner {

    func peripheral_(_ peripheral: CBPeripheralType, didDiscoverServices error: Error?) {

        guard case let .connecting(sorcID) = connectionState,
            peripheralMatchingSorcID(sorcID)?.identifier == peripheral.identifier else { return }

        if error != nil {
            disconnect(withAction: .connectingFailed(sorcID: sorcID))
        } else {
            for service in peripheral.services_! {
                let characteristics = [CBUUID(string: writeCharacteristicId), CBUUID(string: notifyCharacteristicId)]
                peripheral.discoverCharacteristics(characteristics, for: service)
            }
        }
    }

    func peripheral_(_ peripheral: CBPeripheralType, didDiscoverCharacteristicsFor service: CBServiceType, error: Error?) {

        guard case let .connecting(sorcID) = connectionState,
            peripheralMatchingSorcID(sorcID)?.identifier == peripheral.identifier else { return }

        if error != nil {
            disconnect(withAction: .connectingFailed(sorcID: sorcID))
        } else {
            for characteristic in service.characteristics_! {
                if characteristic.uuid == CBUUID(string: notifyCharacteristicId) {
                    notifyCharacteristic = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                } else if characteristic.uuid == CBUUID(string: writeCharacteristicId) {
                    writeCharacteristic = characteristic
                }
            }
        }

        if writeCharacteristic != nil && notifyCharacteristic != nil {
            connectionChange.onNext(.init(state: .connected(sorcID: sorcID),
                                          action: .connectionEstablished(sorcID: sorcID)))
        }
    }

    func peripheral_(_: CBPeripheralType, didUpdateValueFor characteristic: CBCharacteristicType, error _: Error?) {
        // TODO: handle error
        if characteristic.uuid == CBUUID(string: notifyCharacteristicId), let data = characteristic.value {
            delegate?.transferDidReceivedData(self, data: data)
        }
    }

    func peripheral_(_: CBPeripheralType, didWriteValueFor _: CBCharacteristicType, error _: Error?) {
        // TODO: handle error
        delegate?.transferDidSendData(self)
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEScanner: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        centralManagerDidUpdateState_(central as CBCentralManagerType)
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        centralManager_(central as CBCentralManagerType, didDiscover: peripheral as CBPeripheralType, advertisementData: advertisementData, rssi: RSSI)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        centralManager_(central as CBCentralManagerType, didConnect: peripheral as CBPeripheralType)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        centralManager_(central as CBCentralManagerType, didFailToConnect: peripheral as CBPeripheralType, error: error)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        centralManager_(central as CBCentralManagerType, didDisconnectPeripheral: peripheral as CBPeripheralType, error: error)
    }
}

// MARK: - CBPeripheralDelegate

extension BLEScanner: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        peripheral_(peripheral as CBPeripheralType, didDiscoverServices: error)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        peripheral_(peripheral as CBPeripheralType, didDiscoverCharacteristicsFor: service as CBServiceType, error: error)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        peripheral_(peripheral, didUpdateValueFor: characteristic as CBCharacteristicType, error: error)
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        peripheral_(peripheral as CBPeripheralType, didWriteValueFor: characteristic, error: error)
    }
}
