//
//  BLEScanner.swift
//  BLE
//
//  Created by Ke Song on 21.06.16.
//  Copyright © 2016 Huf Secure Mobile. All rights reserved.
//

import UIKit
import CoreBluetooth

protocol CBCentralManagerType: class {

    weak var delegate: CBCentralManagerDelegate? { get set }

    var state: CBManagerState { get }

    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String: Any]?)

    func connect(_ peripheral: CBPeripheralType, options: [String: Any]?)

    func cancelPeripheralConnection(_ peripheral: CBPeripheralType)
}

extension CBCentralManager: CBCentralManagerType {

    func connect(_ peripheral: CBPeripheralType, options: [String: Any]?) {
        connect(peripheral as! CBPeripheral, options: options)
    }

    func cancelPeripheralConnection(_ peripheral: CBPeripheralType) {
        cancelPeripheralConnection(peripheral as! CBPeripheral)
    }
}

protocol CBPeripheralType: class {

    weak var delegate: CBPeripheralDelegate? { get set }

    var services_: [CBServiceType]? { get }

    var identifier: UUID { get }

    func discoverServices(_ serviceUUIDs: [CBUUID]?)

    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBServiceType)

    func writeValue(_ data: Data, for characteristic: CBCharacteristicType, type: CBCharacteristicWriteType)

    func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristicType)
}

extension CBPeripheral: CBPeripheralType {

    var services_: [CBServiceType]? {
        return services
    }

    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBServiceType) {
        discoverCharacteristics(characteristicUUIDs, for: service as! CBService)
    }

    func writeValue(_ data: Data, for characteristic: CBCharacteristicType, type: CBCharacteristicWriteType) {
        writeValue(data, for: characteristic as! CBCharacteristic, type: type)
    }

    func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristicType) {
        setNotifyValue(enabled, for: characteristic as! CBCharacteristic)
    }
}

protocol CBServiceType: class {

    var characteristics_: [CBCharacteristicType]? { get }
}

extension CBService: CBServiceType {

    var characteristics_: [CBCharacteristicType]? {
        return characteristics
    }
}

protocol CBCharacteristicType: class {

    var uuid: CBUUID { get }
    var value: Data? { get }
}

extension CBCharacteristic: CBCharacteristicType {}

/// Delegatation of CBManager state changes.
protocol BLEScannerDelegate: class {
    func didUpdateState()
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
class BLEScanner: NSObject, DataTransfer, CBCentralManagerDelegate, CBPeripheralDelegate {

    /// delegate to handle CBManager state changes.
    weak var bleScannerDelegate: BLEScannerDelegate?

    /// delegate for message tranfer
    weak var delegate: DataTransferDelegate?

    /// central mananger object defined in Core Bluetooth
    var centralManager: CBCentralManagerType!

    private(set) var connectionState = TransferConnectionState.disconnected

    /// Device id as String
    fileprivate var deviceId = "EF82084D-BFAD-4ABE-90EE-2552C20C5765"
    /// Device id as String
    fileprivate var serviceId = "d1cf0603-b501-4569-a4b9-e47ad3f628a5"
    /// notify characteristic id as String
    fileprivate var notifyCharacteristicId = "d1d7a6b6-457e-458a-b237-a9df99b3d98b"
    /// write characteristic id as String
    fileprivate var writeCharacteristicId = "c8e58f23-9417-41c6-97a8-70f6b2c8cab9"
    /// write characteristice object defined in Core Bluetooth
    fileprivate var writeCharacteristic: CBCharacteristicType?
    /// Notify characteristic object defined in Core Bluetooth
    fileprivate var notifyCharacteristic: CBCharacteristicType?

    /**
     Initialization end point for SID Scanner

     - parameter sidID: The sid id as String

     - returns: Scanner object
     */
    required init(centralManager: CBCentralManagerType) {
        super.init()
        self.centralManager = centralManager
        centralManager.delegate = self
    }

    convenience override init() {
        self.init(centralManager: CBCentralManager(delegate: nil, queue: nil, options: [CBPeripheralManagerOptionShowPowerAlertKey: 0]))
    }

    deinit {
        disconnect()
    }

    /**
     To check if the current bluetooth central manager has powered On

     - returns: Central manager state is powered on or notas bool
     */
    func isPoweredOn() -> Bool {
        return centralManager.state == .poweredOn
    }

    func connectToSorc(_ sorc: SID) {
        guard let peripheral = sorc.peripheral else {
            print("BLEScanner: Try to connect to nil peripheral which is not possible.")
            return
        }
        switch connectionState {
        case let .connecting(currentSorc):
            if currentSorc != sorc {
                disconnect()
                updateConnectionState(.connecting(sorc: sorc))
            }
            centralManager.connect(peripheral, options: nil)
        case let .connected(currentSorc):
            if currentSorc != sorc {
                disconnect()
                updateConnectionState(.connecting(sorc: sorc))
                centralManager.connect(peripheral, options: nil)
            }
        case .disconnected:
            updateConnectionState(.connecting(sorc: sorc))
            centralManager.connect(peripheral, options: nil)
        }
    }

    func disconnect() {
        switch connectionState {
        case let .connecting(sorc), let .connected(sorc):
            if let peripheral = sorc.peripheral {
                centralManager.cancelPeripheralConnection(peripheral)
            }
            writeCharacteristic = nil
            notifyCharacteristic = nil
            updateConnectionState(.disconnected)
        case .disconnected: break
        }
    }

    /**
     Sending data to current connected peripheral

     - parameter data: NSData that will be sended to SID
     */
    func sendData(_ data: Data) {
        guard case let .connected(sorc) = connectionState,
            let characteristic = writeCharacteristic,
            let peripheral = sorc.peripheral else { return }

        peripheral.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
    }

    fileprivate func startScan() {
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: 1])
    }

    // MARK: - Private methods

    fileprivate func updateConnectionState(_ state: TransferConnectionState) {
        connectionState = state
        delegate?.transferDidChangedConnectionState(self, state: connectionState)
    }

    // MARK: - CBCentralManagerDelegate

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

    // MARK: - CBPeripheralDelegate

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

extension BLEScanner {

    // MARK: - CBCentralManagerDelegate

    func centralManagerDidUpdateState_(_ central: CBCentralManagerType) {
        consoleLog("BLEScanner Central updated state: \(central.state)")

        bleScannerDelegate?.didUpdateState()
        if central.state == .poweredOn {
            startScan()
        }
    }

    func centralManager_(_: CBCentralManagerType, didDiscover peripheral: CBPeripheralType, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data else {
            return
        }
        let sidID = manufacturerData.toHexString()
        let foundSid = SID(sidID: sidID, peripheral: peripheral, discoveryDate: Date(), isConnected: false, rssi: RSSI.intValue)
        delegate?.transferDidDiscoveredSidId(self, newSid: foundSid)
    }

    func centralManager_(_: CBCentralManagerType, didConnect peripheral: CBPeripheralType) {
        consoleLog("Central connected to peripheral: \(peripheral.identifier.uuidString)")

        guard case let .connecting(sorc) = connectionState, sorc.peripheral?.identifier == peripheral.identifier else { return }
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: self.serviceId)])
    }

    func centralManager_(_: CBCentralManagerType, didFailToConnect peripheral: CBPeripheralType, error: Error?) {
        consoleLog("Central failed connecting to peripheral: \(error?.localizedDescription ?? "Unknown error")")

        guard case let .connecting(sorc) = connectionState, sorc.peripheral?.identifier == peripheral.identifier else { return }
        updateConnectionState(.disconnected)
        delegate?.transferDidFailToConnectSid(self, sid: sorc, error: error)
    }

    func centralManager_(_: CBCentralManagerType, didDisconnectPeripheral peripheral: CBPeripheralType, error _: Error?) {
        guard case let .connected(sorc) = connectionState, sorc.peripheral?.identifier == peripheral.identifier else { return }
        updateConnectionState(.disconnected)
    }

    // MARK: - CBPeripheralDelegate

    func peripheral_(_ peripheral: CBPeripheralType, didDiscoverServices error: Error?) {

        guard case let .connecting(sorc) = connectionState, sorc.peripheral?.identifier == peripheral.identifier else { return }

        if error != nil {
            disconnect()
            delegate?.transferDidFailToConnectSid(self, sid: sorc, error: error)
        } else {
            for service in peripheral.services_! {
                peripheral.discoverCharacteristics([CBUUID(string: self.writeCharacteristicId), CBUUID(string: self.notifyCharacteristicId)], for: service)
            }
        }
    }

    func peripheral_(_ peripheral: CBPeripheralType, didDiscoverCharacteristicsFor service: CBServiceType, error: Error?) {

        guard case var .connecting(sorc) = connectionState, sorc.peripheral?.identifier == peripheral.identifier else { return }

        if error != nil {
            disconnect()
            delegate?.transferDidFailToConnectSid(self, sid: sorc, error: error)
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
            updateConnectionState(.connected(sorc: sorc))
            delegate?.transferDidConnectSid(self, sid: sorc)
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
