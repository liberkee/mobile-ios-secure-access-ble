//
//  SorcConnectionManager.swift
//  SecureAccessBLE
//
//  Copyright © 2016 Huf Secure Mobile. All rights reserved.
//

import CoreBluetooth
import CommonUtils

private class DiscoveredSorc {

    let sorcID: String
    var peripheral: CBPeripheralType
    let discoveryDate: Date
    let rssi: Int

    init(sorcID: String, peripheral: CBPeripheralType, discoveryDate: Date, rssi: Int) {
        self.sorcID = sorcID
        self.peripheral = peripheral
        self.discoveryDate = discoveryDate
        self.rssi = rssi
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
class SorcConnectionManager: NSObject, DataTransfer {

    let isPoweredOn: BehaviorSubject<Bool>
    let discoveryChange = ChangeSubject<DiscoveryChange>(state: Set<SorcID>())
    let connectionChange = ChangeSubject<ConnectionChange>(state: .disconnected)

    let sentData = PublishSubject<Error?>()
    let receivedData = PublishSubject<Result<Data>>()

    fileprivate let deviceId = "EF82084D-BFAD-4ABE-90EE-2552C20C5765"
    fileprivate let serviceId = "d1cf0603-b501-4569-a4b9-e47ad3f628a5"
    fileprivate let notifyCharacteristicId = "d1d7a6b6-457e-458a-b237-a9df99b3d98b"
    fileprivate let writeCharacteristicId = "c8e58f23-9417-41c6-97a8-70f6b2c8cab9"

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

    fileprivate var connectedSid: DiscoveredSorc? {
        if case let .connected(sorcID) = connectionState {
            return discoveredSorcs[sorcID]
        }
        return nil
    }

    fileprivate var connectionState: ConnectionChange.State {
        return connectionChange.state
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
            print("SorcConnectionManager: Try to connect to SORC that is not discovered.")
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
            discoveredSorcs[sorcID] = nil
            updateDiscoveryChange(action: .disconnectSorc(sorcID))
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
        let outdatedSorcs = Array(discoveredSorcs.values).filter { (sorc) -> Bool in
            let outdated = systemClock.timeIntervalSinceNow(for: sorc.discoveryDate) < -sorcOutdatedDurationSeconds
            return outdated && sorc.sorcID != self.connectedSid?.sorcID
        }
        let outdatedSorcIDs = outdatedSorcs.map { $0.sorcID }
        if outdatedSorcIDs.count > 0 {
            for sorcID in outdatedSorcIDs {
                discoveredSorcs[sorcID] = nil
            }
            updateDiscoveryChange(action: .sorcsLost(Set(outdatedSorcIDs)))
        }
    }

    fileprivate func updateDiscoveredSorcsWithNewSorc(_ sorc: DiscoveredSorc) {
        let sorcCopy = sorc
        if let connectedSid = connectedSid, sorcCopy.sorcID == connectedSid.sorcID {
            sorcCopy.peripheral = connectedSid.peripheral
        }
        let replacedSidID = discoveredSorcs.updateValue(sorcCopy, forKey: sorcCopy.sorcID)
        if replacedSidID == nil {
            updateDiscoveryChange(action: .sorcDiscovered(sorc.sorcID))
        }
    }

    fileprivate func resetDiscoveredSorcs() {
        discoveredSorcs = [:]
        updateDiscoveryChange(action: .sorcsReset)
    }

    fileprivate func updateDiscoveryChange(action: DiscoveryChange.Action) {
        let change = DiscoveryChange(state: Set(discoveredSorcs.keys), action: action)
        discoveryChange.onNext(change)
    }

    fileprivate func sorcMatchingSorcID(_ sorcID: SorcID) -> DiscoveredSorc? {
        return discoveredSorcs.values
            .filter { $0.sorcID.lowercased() == sorcID.replacingOccurrences(of: "-", with: "").lowercased() }
            .first
    }

    fileprivate func peripheralMatchingSorcID(_ sorcID: SorcID) -> CBPeripheralType? {
        return sorcMatchingSorcID(sorcID)?.peripheral
    }
}

// MARK: - CBCentralManagerDelegate_

extension SorcConnectionManager {

    func centralManagerDidUpdateState_(_ central: CBCentralManagerType) {
        consoleLog("SorcConnectionManager Central updated state: \(central.state)")

        isPoweredOn.onNext(central.state == .poweredOn)
        if central.state == .poweredOn {
            startScan()
        } else {
            resetDiscoveredSorcs()
        }
    }

    func centralManager_(_: CBCentralManagerType, didDiscover peripheral: CBPeripheralType,
                         advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data else {
            return
        }
        let sorcID = manufacturerData.toHexString()
        let sorc = DiscoveredSorc(sorcID: sorcID, peripheral: peripheral, discoveryDate: systemClock.now(), rssi: RSSI.intValue)
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

    func centralManager_(_: CBCentralManagerType, didDisconnectPeripheral peripheral: CBPeripheralType,
                         error _: Error?) {

        guard case let .connected(sorcID) = connectionState,
            let sorc = sorcMatchingSorcID(sorcID),
            sorc.peripheral.identifier == peripheral.identifier else { return }

        discoveredSorcs[sorcID] = nil
        updateDiscoveryChange(action: .sorcDisconnected(sorcID))
        connectionChange.onNext(.init(state: .disconnected, action: .disconnected(sorcID: sorcID)))
    }
}

// MARK: - CBPeripheralDelegate_

extension SorcConnectionManager {

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

    func peripheral_(_ peripheral: CBPeripheralType, didDiscoverCharacteristicsFor service: CBServiceType,
                     error: Error?) {

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

    func peripheral_(_: CBPeripheralType, didUpdateValueFor characteristic: CBCharacteristicType, error: Error?) {
        guard characteristic.uuid == CBUUID(string: notifyCharacteristicId) else { return }
        if let error = error {
            receivedData.onNext(.error(error))
        } else if let data = characteristic.value {
            receivedData.onNext(.success(data))
        } else {
            print("SorcConnectionManager: No error but characteristic value was nil which is unexpected.")
        }
    }

    func peripheral_(_: CBPeripheralType, didWriteValueFor characteristic: CBCharacteristicType, error: Error?) {
        guard characteristic.uuid == CBUUID(string: writeCharacteristicId) else { return }
        sentData.onNext(error)
    }
}
