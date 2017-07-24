//
//  BLEScanner.swift
//  BLE
//
//  Created by Ke Song on 21.06.16.
//  Copyright © 2016 Huf Secure Mobile. All rights reserved.
//

import UIKit
import CoreBluetooth

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
    var peripheral: CBPeripheral?
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
    if (lhs.peripheral != rhs.peripheral) || (lhs.sidID != rhs.sidID) {
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
open class BLEScanner: NSObject, DataTransfer, CBCentralManagerDelegate, CBPeripheralDelegate {

    /// delegate to handle CBManager state changes.
    weak var bleScannerDelegate: BLEScannerDelegate?

    /// delegate for message tranfer
    weak var delegate: DataTransferDelegate?

    /// central mananger object defined in Core Bluetooth
    var centralManager: CBCentralManager!

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
    private var writeCharacteristic: CBCharacteristic?
    /// Notify characteristic object defined in Core Bluetooth
    private var notifyCharacteristic: CBCharacteristic?

    /**
     Initialization end point for SID Scanner

     - parameter sidID: The sid id as String

     - returns: Scanner object
     */
    public required init(sidID _: NSString = "") {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBPeripheralManagerOptionShowPowerAlertKey: 0])
    }

    /**
     Deinitialization end point
     */
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

    /**
     Start BLE-Scanner to scan perihperals with allowing duplicatesKey options
     */
    private func startScan() {
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: 1])
    }

    // MARK: - Private methods

    private func updateConnectionState(_ state: TransferConnectionState) {
        connectionState = state
        delegate?.transferDidChangedConnectionState(self, state: connectionState)
    }

    // MARK: - CBCentralDelegate
    /**
     See CBCentralManager documentation from coreBluetooth
     */
    open func centralManagerDidUpdateState(_ central: CBCentralManager) {
        consoleLog("BLEScanner Central updated state: \(central.state)")

        bleScannerDelegate?.didUpdateState()
        if central.state == .poweredOn {
            startScan()
        }
    }

    /**
     See CBCentralManager documentation from coreBluetooth
     */
    open func centralManager(_: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data else {
            return
        }
        let sidID = manufacturerData.toHexString()
        let foundSid = SID(sidID: sidID, peripheral: peripheral, discoveryDate: Date(), isConnected: false, rssi: RSSI.intValue)
        delegate?.transferDidDiscoveredSidId(self, newSid: foundSid)
    }

    /**
     See CBCentralManager documentation from coreBluetooth
     */
    open func centralManager(_: CBCentralManager, didConnect peripheral: CBPeripheral) {
        consoleLog("Central connected to peripheral: \(peripheral.identifier.uuidString)")

        guard case let .connecting(sorc) = connectionState, sorc.peripheral == peripheral else { return }
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: self.serviceId)])
    }

    /**
     See CBCentralManager documentation from coreBluetooth
     */
    open func centralManager(_: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        consoleLog("Central failed connecting to peripheral: \(error?.localizedDescription ?? "Unkown error")")

        guard case let .connecting(sorc) = connectionState, sorc.peripheral == peripheral else { return }
        updateConnectionState(.disconnected)
        delegate?.transferDidFailToConnectSid(self, sid: sorc, error: error)
    }

    /**
     See CBCentralManager documentation from coreBluetooth
     */
    open func centralManager(_: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error _: Error?) {
        guard case let .connected(sorc) = connectionState, sorc.peripheral == peripheral else { return }
        updateConnectionState(.disconnected)
    }

    // MARK: - CBPeripheralDelegate
    /**
     See CBPeripheralDelegate documentation from coreBluetooth
     */
    open func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {

        guard case let .connecting(sorc) = connectionState, sorc.peripheral == peripheral else { return }

        if error != nil {
            disconnect()
            delegate?.transferDidFailToConnectSid(self, sid: sorc, error: error)
        } else {
            for service in peripheral.services! {
                peripheral.discoverCharacteristics([CBUUID(string: self.writeCharacteristicId), CBUUID(string: self.notifyCharacteristicId)], for: service)
            }
        }
    }

    /**
     See CBPeripheralDelegate documentation from coreBluetooth
     */
    open func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {

        guard case var .connecting(sorc) = connectionState, sorc.peripheral == peripheral else { return }

        if error != nil {
            disconnect()
            delegate?.transferDidFailToConnectSid(self, sid: sorc, error: error)
        } else {
            for characteristic in service.characteristics! {
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

    /**
     See CBPeripheralDelegate documentation from coreBluetooth
     */
    open func peripheral(_: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error _: Error?) {
        // TODO: handle error
        if characteristic == notifyCharacteristic {
            delegate?.transferDidReceivedData(self, data: characteristic.value!)
        }
    }

    /**
     See CBPeripheralDelegate documentation from coreBluetooth
     */
    open func peripheral(_: CBPeripheral, didWriteValueFor _: CBCharacteristic, error _: Error?) {
        // TODO: handle error
        delegate?.transferDidSendData(self, data: Data())
    }
}
