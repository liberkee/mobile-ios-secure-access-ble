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
public protocol BLEScannerDelegate {
    func didUpdateState()
}

/**
 *  Definition for SID object
 */
public struct SID: Hashable {
    /// SID id as String
    public var sidID: String
    /// Peripheral, that SID object inclusive
    var peripheral: CBPeripheral?
    /// Date that the sid was discovered
    var discoveryDate: Date
    /// If currently connected
    var isConnected: Bool
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
public func == (lhs: SID, rhs: SID) -> Bool {
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
    public var bleScannerDelegate: BLEScannerDelegate?
    
    /// delegate for message tranfer
    weak var delegate: DataTransferDelegate?
    /// connection state default false
    var isConnected = false
    /// if central manager powered on
    var centralManagerPoweredOn : Bool!
    /// Device id as String
    fileprivate var deviceId = "EF82084D-BFAD-4ABE-90EE-2552C20C5765"
    /// Device id as String
    fileprivate var serviceId = "d1cf0603-b501-4569-a4b9-e47ad3f628a5"
    /// notify characteristic id as String
    fileprivate var notifyCharacteristicId = "d1d7a6b6-457e-458a-b237-a9df99b3d98b"
    /// write characteristic id as String
    fileprivate var writeCharacteristicId = "c8e58f23-9417-41c6-97a8-70f6b2c8cab9"
    /// the saved SIDs list, manager did found
    fileprivate var sids = Set<SID>()
    /// Timer to filter old SIDs
    fileprivate var filterTimer: Timer?
    /// central mananger object defined in Core Bluetooth
    var centralManager: CBCentralManager!
    /// Peripheral object defined in core bluetooth
    open var sidPeripheral: CBPeripheral?
    /// write characteristice object defined in Core Bluetooth
    var writeCharacteristic: CBCharacteristic?
    /// Notify characteristic object defined in Core Bluetooth
    var notifyCharacteristic: CBCharacteristic?
    /// Current connected SID
    var connectingdSid : SID?
    
    /**
     Initialization end point for SID Scanner
     
     - parameter sidID: The sid id as String
     
     - returns: Scanner object
     */
    required public init(sidID: NSString = "") {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBPeripheralManagerOptionShowPowerAlertKey: 0])
        filterTimer = Timer.scheduledTimer(timeInterval: 1.31, target: self, selector: #selector(BLEScanner.shouldFilterOldSidIds), userInfo: nil, repeats: true)
    }
    
    /**
     Convenience initialization end point
     
     - parameter serviceID: Service Id as String
     - parameter notifyID:  Notify characteristic id as String
     - parameter writeID:   write characteristice id as String
     
     - returns: Scanner object
     */
    convenience init(serviceID: String, notifyID: String, writeID: String) {
        self.init()
        serviceId = serviceID
        notifyCharacteristicId = notifyID
        writeCharacteristicId = writeID
    }
    
    /**
     Deinitialization end point
     */
    deinit {
        if self.isConnected {
            self.disconnect()
        } else {
            self.cleanUpSIDs()
            self.resetPeripheral()
        }
    }
    
    /**
     To check if the current bluetooth central manager has powered On
     
     - returns: Central manager state is powered on or notas bool
     */
    open func isPoweredOn() -> Bool {
        //debugPrint("central manager has \(self.centralManager!.state.description)")
        return self.centralManager!.state == .poweredOn
    }
    
    /**
     The central manager connect to connected periheral
     
     - parameter sidId: the sidId as String that current peripheral has
     */
    func connectToSidWithId(_ sidId: String) {
        if let sid = self.sids.filter({$0.sidID.lowercased() == sidId.replacingOccurrences(of: "-", with: "").lowercased()}).first {
            debugPrint("connecting to sid:\(sid.sidID)")
            self.connectingdSid = sid
            self.sidPeripheral = sid.peripheral!
            self.centralManager.connect(sid.peripheral!, options: nil)
        }
    }
    
    /**
     Disconnect peripheral if it was connected, and resetting local saved
     */
    func disconnect() {
        if let peripheral = self.sidPeripheral {
            debugPrint("BLE will be disconnected at: \(CACurrentMediaTime())")
            self.centralManager.cancelPeripheralConnection(peripheral)
        }
        self.cleanUpSIDs()
    }
    
    /**
     Sending data to current connected peripheral
     
     - parameter data: NSData that will be sended to SID
     */
    func sendData(_ data: Data) {
        if let characteristic = self.writeCharacteristic, let peripheral = self.sidPeripheral {
            peripheral.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
            //self.delegate?.didSendData(self, data: NSData())
        }
    }
    
    /**
     Start BLE-Scanner to scan perihperals with allowing duplicatesKey options
     */
    func begineToScan() {
        self.centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: 1])
    }
    
    //MARK: - Helper
    /**
     To empty (reset) all local saved SIDs
     */
    fileprivate func cleanUpSIDs() {
        sids = Set<SID>()
    }
    
    /**
     Reset current peripheral
     */
    fileprivate func resetPeripheral() {
        self.sidPeripheral = nil
        self.connectingdSid = nil
        //self.delegate?.transferDidconnectedSid(self, sid: self.connectingdSid!)
    }
    
    /**
     Check all saved sids with discovery date (time), all older (discovered before 5 seconds)
     sids will be deleted from List. Scanner will be started after delete old sids and the deletion
     will be informed
     */
    func shouldFilterOldSidIds() {
        self.delegate?.transferShouldFilterOldIds(self)
    }
    
    //MARK: CBCentralDelegate
    /**
     See CBCentralManager documentation from coreBluetooth
     */
    open func centralManagerDidUpdateState(_ central: CBCentralManager) {
        consoleLog("Central updated state: \(central.state)")
        
        bleScannerDelegate?.didUpdateState()
        self.centralManagerPoweredOn = central.state == .poweredOn//CBManagerState.poweredOn
        if central.state != .poweredOn {
            self.resetPeripheral()
            self.isConnected = false
            self.delegate?.transferDidChangedConnectionState(self, isConnected: self.isConnected)
            return
        }
        self.delegate?.transferDidChangedConnectionState(self, isConnected: self.isConnected)
        self.begineToScan()
    }
    
    /**
     See CBCentralManager documentation from coreBluetooth
     */
    open func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data else {
            return
        }
        let sidID = manufacturerData.toHexString()
        let foundSid = SID(sidID: sidID, peripheral: peripheral, discoveryDate: Date(), isConnected: false)
        self.sids.insert(foundSid)
        self.delegate?.transferDidDiscoveredSidId(self, newSid:foundSid)
    }
    
    /**
     See CBCentralManager documentation from coreBluetooth
     */
    open func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        consoleLog("Central failed connecting to peripheral: \(error?.localizedDescription ?? "Unkown error")")
        
        debugPrint(error!.localizedDescription)
        self.cleanUpSIDs()
        self.resetPeripheral()
    }
    
    /**
     See CBCentralManager documentation from coreBluetooth
     */
    open func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        consoleLog("Central connected to peripheral: \(peripheral.identifier.uuidString)")
        
        self.isConnected = true
        self.sidPeripheral = peripheral
        //debugPrint("Peripheral did Connected")
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: self.serviceId)])
    }
    
    /**
     See CBCentralManager documentation from coreBluetooth
     */
    open func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        consoleLog("Central disconnected from peripheral: \(peripheral.identifier.uuidString)")
        
        self.isConnected = false
        self.cleanUpSIDs()
        self.resetPeripheral()
        self.begineToScan()
        self.delegate?.transferDidChangedConnectionState(self, isConnected: self.isConnected)
        
    }
    
    //MARK - CBPeripharalDelegate
    /**
     See CBPeripharalDelegate documentation from coreBluetooth
     */
    open func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            debugPrint("Error: \(error!.localizedDescription)")
            self.cleanUpSIDs()
            self.resetPeripheral()
        } else {
            for service in peripheral.services! {
                peripheral.discoverCharacteristics([CBUUID(string: self.writeCharacteristicId), CBUUID(string: self.notifyCharacteristicId)], for: service )
            }
        }
    }
    
    /**
     See CBPeripharalDelegate documentation from coreBluetooth
     */
    open func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            debugPrint("Error: \(error!.localizedDescription)")
            self.cleanUpSIDs()
            self.resetPeripheral()
        } else {
            for characteristic in service.characteristics! {
                if characteristic.uuid == CBUUID(string: self.notifyCharacteristicId) {
                    self.notifyCharacteristic = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                } else if characteristic.uuid == CBUUID(string: self.writeCharacteristicId) {
                    self.writeCharacteristic = characteristic
                }
            }
        }
        
        if self.writeCharacteristic != nil && self.notifyCharacteristic != nil {
            if self.connectingdSid?.peripheral == peripheral {
                self.connectingdSid?.isConnected = true
            }
            self.delegate?.transferDidChangedConnectionState(self, isConnected: isConnected)
            self.delegate?.transferDidconnectedSid(self, sid: self.connectingdSid!)
        }
    }
    
    /**
     See CBPeripharalDelegate documentation from coreBluetooth
     */
    open func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic == self.notifyCharacteristic {
            //            debugPrint("Received Package at time: \(CACurrentMediaTime())")
            self.delegate?.transferDidReceivedData(self, data: characteristic.value!)
        }
    }
    
    /**
     See CBPeripharalDelegate documentation from coreBluetooth
     */
    open func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        //        debugPrint("Did send Package at time: \(CACurrentMediaTime())")
        self.delegate?.transferDidSendData(self, data: Data())
    }
}

