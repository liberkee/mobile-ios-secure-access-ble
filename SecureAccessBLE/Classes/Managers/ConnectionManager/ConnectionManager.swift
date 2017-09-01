//
//  ConnectionManager.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import CoreBluetooth
import CommonUtils

private class DiscoveredSorc {

    let sorcID: SorcID
    var peripheral: CBPeripheralType
    let discoveryDate: Date
    let rssi: Int

    init(sorcID: SorcID, peripheral: CBPeripheralType, discoveryDate: Date, rssi: Int) {
        self.sorcID = sorcID
        self.peripheral = peripheral
        self.discoveryDate = discoveryDate
        self.rssi = rssi
    }
}

private extension SorcInfo {

    init(discoveredSorc: DiscoveredSorc) {
        sorcID = discoveredSorc.sorcID
        discoveryDate = discoveredSorc.discoveryDate
        rssi = discoveredSorc.rssi
    }
}

private extension CBManagerState {

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

/// Manages the discovery and connection of SORCs
class ConnectionManager: NSObject, ConnectionManagerType, BluetoothStatusProviderType, ScannerType {

    let isBluetoothEnabled: BehaviorSubject<Bool>
    let discoveryChange = ChangeSubject<DiscoveryChange>(state: [:])
    let connectionChange = ChangeSubject<PhysicalConnectionChange>(state: .disconnected)

    let dataSent = PublishSubject<Error?>()
    let dataReceived = PublishSubject<Result<Data>>()

    fileprivate let deviceID = "EF82084D-BFAD-4ABE-90EE-2552C20C5765"
    fileprivate let serviceID = "d1cf0603-b501-4569-a4b9-e47ad3f628a5"
    fileprivate let notifyCharacteristicID = "d1d7a6b6-457e-458a-b237-a9df99b3d98b"
    fileprivate let writeCharacteristicID = "c8e58f23-9417-41c6-97a8-70f6b2c8cab9"

    fileprivate var writeCharacteristic: CBCharacteristicType?
    fileprivate var notifyCharacteristic: CBCharacteristicType?

    private var centralManager: CBCentralManagerType!
    fileprivate let systemClock: SystemClockType

    /// Timer to remove outdated discovered SORCs
    fileprivate var filterTimer: Timer?

    /// The duration a SORC is considered outdated if last discovery date is longer ago than this duration
    private let sorcOutdatedDurationSeconds: Double = 5

    /// The SORCs that were discovered and were not removed by the filterTimer
    fileprivate var discoveredSorcs = [SorcID: DiscoveredSorc]()

    fileprivate var connectedSorc: DiscoveredSorc? {
        if case let .connected(sorcID) = connectionState {
            return discoveredSorcs[sorcID]
        }
        return nil
    }

    fileprivate var connectionState: PhysicalConnectionChange.State {
        return connectionChange.state
    }

    required init(centralManager: CBCentralManagerType, systemClock: SystemClockType,
                  createTimer: CreateTimer) {

        self.systemClock = systemClock
        isBluetoothEnabled = BehaviorSubject(value: centralManager.state == .poweredOn)
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
            print("ConnectionManager: Try to connect to SORC that is not discovered.")
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
        disconnect(withAction: nil)
    }

    func sendData(_ data: Data) {
        guard case let .connected(sorcID) = connectionState,
            let characteristic = writeCharacteristic,
            let peripheral = peripheralMatchingSorcID(sorcID) else { return }

        peripheral.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
    }

    // MARK: - Private methods

    fileprivate func disconnect(withAction action: PhysicalConnectionChange.Action?) {
        switch connectionState {
        case let .connecting(sorcID), let .connected(sorcID):
            if let peripheral = peripheralMatchingSorcID(sorcID) {
                centralManager.cancelPeripheralConnection(peripheral)
            }
            discoveredSorcs[sorcID] = nil
            updateDiscoveryChange(action: .disconnect(sorcID: sorcID))
            writeCharacteristic = nil
            notifyCharacteristic = nil
            connectionChange.onNext(.init(state: .disconnected, action: action ?? .disconnect(sorcID: sorcID)))
        case .disconnected: break
        }
    }

    fileprivate func startScan() {
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: 1])
    }

    private func removeOutdatedSorcs() {
        let outdatedSorcs = Array(discoveredSorcs.values).filter { (sorc) -> Bool in
            let outdated = systemClock.timeIntervalSinceNow(for: sorc.discoveryDate) < -sorcOutdatedDurationSeconds
            return outdated && sorc.sorcID != self.connectedSorc?.sorcID
        }
        let outdatedSorcIDs = outdatedSorcs.map { $0.sorcID }
        if outdatedSorcIDs.count > 0 {
            for sorcID in outdatedSorcIDs {
                discoveredSorcs[sorcID] = nil
            }
            updateDiscoveryChange(action: .lost(sorcIDs: Set(outdatedSorcIDs)))
        }
    }

    fileprivate func updateDiscoveredSorcsWithNewSorc(_ sorc: DiscoveredSorc) {
        if let connectedSorc = connectedSorc, sorc.sorcID == connectedSorc.sorcID {
            sorc.peripheral = connectedSorc.peripheral
        }
        let replaced = discoveredSorcs.updateValue(sorc, forKey: sorc.sorcID) != nil
        let action: DiscoveryChange.Action = replaced ?
            .rediscovered(sorcID: sorc.sorcID) : .discovered(sorcID: sorc.sorcID)
        updateDiscoveryChange(action: action)
    }

    fileprivate func resetDiscoveredSorcs() {
        discoveredSorcs = [:]
        updateDiscoveryChange(action: .reset)
    }

    fileprivate func updateDiscoveryChange(action: DiscoveryChange.Action) {
        var sorcInfos = [SorcID: SorcInfo]()
        for sorc in discoveredSorcs.values {
            let sorcInfo = SorcInfo(discoveredSorc: sorc)
            sorcInfos[sorcInfo.sorcID] = sorcInfo
        }
        let change = DiscoveryChange(state: sorcInfos, action: action)
        discoveryChange.onNext(change)
    }

    fileprivate func peripheralMatchingSorcID(_ sorcID: SorcID) -> CBPeripheralType? {
        return discoveredSorcs[sorcID]?.peripheral
    }
}

// MARK: - CBCentralManagerDelegate_

extension ConnectionManager {

    func centralManagerDidUpdateState_(_ central: CBCentralManagerType) {
        consoleLog("ConnectionManager Central updated state: \(central.state)")

        isBluetoothEnabled.onNext(central.state == .poweredOn)
        if central.state == .poweredOn {
            startScan()
        } else {
            resetDiscoveredSorcs()
        }
    }

    func centralManager_(_: CBCentralManagerType, didDiscover peripheral: CBPeripheralType,
                         advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
            let sorcID = manufacturerData.uuidString else { return }

        let sorc = DiscoveredSorc(sorcID: sorcID, peripheral: peripheral, discoveryDate: systemClock.now(), rssi: RSSI.intValue)
        updateDiscoveredSorcsWithNewSorc(sorc)
    }

    func centralManager_(_: CBCentralManagerType, didConnect peripheral: CBPeripheralType) {
        consoleLog("Central connected to peripheral: \(peripheral.identifier.uuidString)")

        guard case let .connecting(sorcID) = connectionState,
            peripheralMatchingSorcID(sorcID)?.identifier == peripheral.identifier else { return }

        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: serviceID)])
    }

    func centralManager_(_: CBCentralManagerType, didFailToConnect peripheral: CBPeripheralType, error: Error?) {
        consoleLog("Central failed connecting to peripheral: \(error?.localizedDescription ?? "Unknown error")")

        guard case let .connecting(sorcID) = connectionState,
            peripheralMatchingSorcID(sorcID)?.identifier == peripheral.identifier else { return }

        connectionChange.onNext(.init(state: .disconnected, action: .connectingFailed(sorcID: sorcID)))
    }

    func centralManager_(_: CBCentralManagerType, didDisconnectPeripheral peripheral: CBPeripheralType,
                         error _: Error?) {

        guard case let .connected(sorcID) = connectionState,
            peripheralMatchingSorcID(sorcID)?.identifier == peripheral.identifier else { return }

        discoveredSorcs[sorcID] = nil
        updateDiscoveryChange(action: .disconnected(sorcID: sorcID))
        connectionChange.onNext(.init(state: .disconnected, action: .connectionLost(sorcID: sorcID)))
    }
}

// MARK: - CBPeripheralDelegate_

extension ConnectionManager {

    func peripheral_(_ peripheral: CBPeripheralType, didDiscoverServices error: Error?) {

        guard case let .connecting(sorcID) = connectionState,
            peripheralMatchingSorcID(sorcID)?.identifier == peripheral.identifier else { return }

        if error != nil {
            disconnect(withAction: .connectingFailed(sorcID: sorcID))
        } else {
            for service in peripheral.services_! {
                let characteristics = [CBUUID(string: writeCharacteristicID), CBUUID(string: notifyCharacteristicID)]
                peripheral.discoverCharacteristics(characteristics, for: service)
            }
        }
    }

    func peripheral_(_ peripheral: CBPeripheralType, didDiscoverCharacteristicsFor service: CBServiceType,
                     error: Error?) {

        guard case let .connecting(sorcID) = connectionState,
            peripheralMatchingSorcID(sorcID)?.identifier == peripheral.identifier else { return }

        if error != nil {
            disconnect(withAction: .connectingFailed(sorcID: sorcID))
        } else {
            for characteristic in service.characteristics_! {
                if characteristic.uuid == CBUUID(string: notifyCharacteristicID) {
                    notifyCharacteristic = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                } else if characteristic.uuid == CBUUID(string: writeCharacteristicID) {
                    writeCharacteristic = characteristic
                }
            }
        }

        if writeCharacteristic != nil && notifyCharacteristic != nil {
            connectionChange.onNext(.init(state: .connected(sorcID: sorcID),
                                          action: .connectionEstablished(sorcID: sorcID)))
        }
    }

    func peripheral_(_: CBPeripheralType, didUpdateValueFor characteristic: CBCharacteristicType, error: Error?) {
        guard characteristic.uuid == CBUUID(string: notifyCharacteristicID) else { return }
        if let error = error {
            dataReceived.onNext(.failure(error))
        } else if let data = characteristic.value {
            dataReceived.onNext(.success(data))
        } else {
            print("ConnectionManager: No error but characteristic value was nil which is unexpected.")
        }
    }

    func peripheral_(_: CBPeripheralType, didWriteValueFor characteristic: CBCharacteristicType, error: Error?) {
        guard characteristic.uuid == CBUUID(string: writeCharacteristicID) else { return }
        dataSent.onNext(error)
    }
}
