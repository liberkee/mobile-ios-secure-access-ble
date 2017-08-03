//
//  BLEScanner.swift
//  BLE
//
//  Created by Ke Song on 21.06.16.
//  Copyright © 2016 Huf Secure Mobile. All rights reserved.
//

import CoreBluetooth
import CommonUtils

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

enum TransferConnectionState {
    case disconnected
    case connecting(sorc: SID)
    case connected(sorc: SID)
}

/**
 *  Definition for SID object
 */
struct SID: Hashable {
    /// SID id as String
    var sidID: String
    /// Peripheral, that SID object inclusive
    var peripheral: CBPeripheralType?
    /// Date that the sid was discovered
    var discoveryDate: Date
    /// If currently connected
    var isConnected: Bool
    /// The rssi on discovery in dbm
    public var rssi: Int
    /// has value as Int fo SID id
    public var hashValue: Int {
        return sidID.hashValue
    }
}

/**
 To compare if both objects equal

 - parameter lhs: first object to compare
 - parameter rhs: second object to compare

 - returns: both objects equal or not
 */
func == (lhs: SID, rhs: SID) -> Bool {
    if (lhs.peripheral?.identifier != rhs.peripheral?.identifier) || (lhs.sidID != rhs.sidID) {
        return false
    }

    return true
}

//  extension the Central manager state to allow showing status as String
extension CBCentralManagerState {
    /// Externsion point for Central manager connection state
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

    /// delegate for message tranfer
    weak var delegate: DataTransferDelegate?

    /// central mananger object defined in Core Bluetooth
    var centralManager: CBCentralManagerType!

    let isPoweredOn: BehaviorSubject<Bool>

    let discoveryChange = BehaviorSubject(value: DiscoveryChange(state: Set<SorcID>(), action: .initial))

    let connectionState = BehaviorSubject(value: TransferConnectionState.disconnected)

    /// Device id as String
    fileprivate let deviceId = "EF82084D-BFAD-4ABE-90EE-2552C20C5765"
    /// Device id as String
    fileprivate let serviceId = "d1cf0603-b501-4569-a4b9-e47ad3f628a5"
    /// notify characteristic id as String
    fileprivate let notifyCharacteristicId = "d1d7a6b6-457e-458a-b237-a9df99b3d98b"
    /// write characteristic id as String
    fileprivate let writeCharacteristicId = "c8e58f23-9417-41c6-97a8-70f6b2c8cab9"
    /// write characteristice object defined in Core Bluetooth
    fileprivate var writeCharacteristic: CBCharacteristicType?
    /// Notify characteristic object defined in Core Bluetooth
    fileprivate var notifyCharacteristic: CBCharacteristicType?

    ////////

    /// Current connected SID object
    fileprivate var connectedSid: SID? {
        if case let .connected(sorc) = connectionState.value {
            return sorc
        }
        return nil
    }

    fileprivate var discoveredSorcs = Set<SID>()

    /// Timer to filter old SIDs
    fileprivate var filterTimer: Timer?

    /// The interval a timer is triggered to remove outdated discovered SORCs
    private let removeOutdatedSorcsTimerIntervalSeconds: Double = 2

    /// The duration a SORC is considered outdated if last discovery date is longer ago than this duration
    private let sorcOutdatedDurationSeconds: Double = 5

    ////////

    /**
     Initialization end point for SID Scanner

     - parameter sidID: The sid id as String

     - returns: Scanner object
     */
    required init(centralManager: CBCentralManagerType) {
        isPoweredOn = BehaviorSubject(value: centralManager.state == .poweredOn)
        super.init()
        self.centralManager = centralManager
        centralManager.delegate = self

        filterTimer = Timer.scheduledTimer(timeInterval: removeOutdatedSorcsTimerIntervalSeconds,
                                           target: self,
                                           selector: #selector(filterOldSidIds),
                                           userInfo: nil,
                                           repeats: true)
    }

    convenience override init() {
        self.init(centralManager: CBCentralManager(delegate: nil, queue: nil, options: [CBPeripheralManagerOptionShowPowerAlertKey: 0]))
    }

    deinit {
        disconnect()
        filterTimer?.invalidate()
    }

    func connectToSorc(_ sorcID: SorcID) {
        let optSorc = discoveredSorcs
            .filter { $0.sidID.lowercased() == sorcID.replacingOccurrences(of: "-", with: "").lowercased() }
            .first
        guard let sorc = optSorc else {
            // TODO: PLAM-963 didFailToConnect?
            print("BLEScanner: Try to connect to SORC that is not discovered.")
            return
        }
        guard let peripheral = sorc.peripheral else {
            // TODO: PLAM-963 didFailToConnect?
            print("BLEScanner: Try to connect to nil peripheral which is not possible.")
            return
        }
        switch connectionState.value {
        case let .connecting(currentSorc):
            if currentSorc != sorc {
                disconnect()
                connectionState.onNext(.connecting(sorc: sorc))
            }
            centralManager.connect(peripheral, options: nil)
        case let .connected(currentSorc):
            if currentSorc != sorc {
                disconnect()
                connectionState.onNext(.connecting(sorc: sorc))
                centralManager.connect(peripheral, options: nil)
            }
        case .disconnected:
            connectionState.onNext(.connecting(sorc: sorc))
            centralManager.connect(peripheral, options: nil)
        }
    }

    func disconnect() {
        switch connectionState.value {
        case let .connecting(sorc), let .connected(sorc):
            if let peripheral = sorc.peripheral {
                centralManager.cancelPeripheralConnection(peripheral)
            }
            writeCharacteristic = nil
            notifyCharacteristic = nil
            connectionState.onNext(.disconnected)
        case .disconnected: break
        }
    }

    /**
     Sending data to current connected peripheral

     - parameter data: NSData that will be sended to SID
     */
    func sendData(_ data: Data) {
        guard case let .connected(sorc) = connectionState.value,
            let characteristic = writeCharacteristic,
            let peripheral = sorc.peripheral else { return }

        peripheral.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
    }

    // MARK: - Private methods

    fileprivate func startScan() {
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: 1])
    }

    /////////// TODO: PLAM-963

    /**
     Check all saved sids with discovery date (time), all older (discovered before 5 seconds)
     sids will be deleted from List. Scanner will be started after delete old sids and the deletion
     will be informed
     */
    func filterOldSidIds() {
        let lostSorcs = discoveredSorcs.filter { (sid) -> Bool in
            let outdated = sid.discoveryDate.timeIntervalSinceNow < -sorcOutdatedDurationSeconds
            if outdated {
                if sid.sidID == self.connectedSid?.sidID {
                    return false
                } else {
                    return true
                }
            } else {
                return false
            }
        }
        if lostSorcs.count > 0 {
            for sid in lostSorcs {
                discoveredSorcs.remove(sid)
            }
            let lostSorcIDs = lostSorcs.map { $0.sidID }
            updateDiscoveryChange(action: .sorcsLost(Set(lostSorcIDs)))
        }
    }

    fileprivate func updateFoundSorcsWithDiscoveredSorc(_ sorc: SID) {
        var sorcCopy = sorc
        if let connectedSid = connectedSid, sorcCopy.sidID == connectedSid.sidID {
            sorcCopy.isConnected = connectedSid.isConnected
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

    /////////// TODO: PLAM-963
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
        let foundSid = SID(sidID: sidID, peripheral: peripheral, discoveryDate: Date(), isConnected: false, rssi: RSSI.intValue)
        updateFoundSorcsWithDiscoveredSorc(foundSid)
    }

    func centralManager_(_: CBCentralManagerType, didConnect peripheral: CBPeripheralType) {
        consoleLog("Central connected to peripheral: \(peripheral.identifier.uuidString)")

        guard case let .connecting(sorc) = connectionState.value,
            sorc.peripheral?.identifier == peripheral.identifier else { return }

        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: self.serviceId)])
    }

    func centralManager_(_: CBCentralManagerType, didFailToConnect peripheral: CBPeripheralType, error: Error?) {
        consoleLog("Central failed connecting to peripheral: \(error?.localizedDescription ?? "Unknown error")")

        guard case let .connecting(sorc) = connectionState.value,
            sorc.peripheral?.identifier == peripheral.identifier else { return }

        connectionState.onNext(.disconnected)

        // TODO: PLAM-963 Send error event?
    }

    func centralManager_(_: CBCentralManagerType, didDisconnectPeripheral peripheral: CBPeripheralType, error _: Error?) {
        guard case let .connected(sorc) = connectionState.value,
            sorc.peripheral?.identifier == peripheral.identifier else { return }

        discoveredSorcs.remove(sorc)
        updateDiscoveryChange(action: .sorcDisconnected(sorc.sidID))
        connectionState.onNext(.disconnected)
    }
}

// MARK: - CBPeripheralDelegate_

extension BLEScanner {

    func peripheral_(_ peripheral: CBPeripheralType, didDiscoverServices error: Error?) {

        guard case let .connecting(sorc) = connectionState.value,
            sorc.peripheral?.identifier == peripheral.identifier else { return }

        if error != nil {
            disconnect()

            // TODO: PLAM-963 Send error event?
        } else {
            for service in peripheral.services_! {
                peripheral.discoverCharacteristics([CBUUID(string: self.writeCharacteristicId), CBUUID(string: self.notifyCharacteristicId)], for: service)
            }
        }
    }

    func peripheral_(_ peripheral: CBPeripheralType, didDiscoverCharacteristicsFor service: CBServiceType, error: Error?) {

        guard case var .connecting(sorc) = connectionState.value,
            sorc.peripheral?.identifier == peripheral.identifier else { return }

        if error != nil {
            disconnect()

            // TODO: PLAM-963 Send error event?
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
            sorc.isConnected = true
            connectionState.onNext(.connected(sorc: sorc))
        }
    }

    func peripheral_(_: CBPeripheralType, didUpdateValueFor characteristic: CBCharacteristicType, error _: Error?) {
        // TODO: handle error
        if characteristic.uuid == CBUUID(string: notifyCharacteristicId) {
            delegate?.transferDidReceivedData(self, data: characteristic.value!)
        }
    }

    func peripheral_(_: CBPeripheralType, didWriteValueFor _: CBCharacteristicType, error _: Error?) {
        // TODO: handle error
        delegate?.transferDidSendData(self, data: Data())
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
