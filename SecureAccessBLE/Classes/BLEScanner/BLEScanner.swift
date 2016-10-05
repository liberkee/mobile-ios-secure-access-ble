//
//  BLEScanner.swift
//  BLE
//
//  Created by Ke Song on 21.06.16.
//  Copyright © 2016 Huf Secure Mobile. All rights reserved.
//

import UIKit
import CoreBluetooth

/**
 *  Definition for SID object
 */
public struct SID: Hashable {
    /// SID id as String
    public var sidID: String
    /// Peripheral, that SID object inclusive
    var peripheral: CBPeripheral?
    /// Date that the sid was discovered
    var discoveryDate: NSDate
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
        case .Unknown: return "Unknown"
        case .Resetting: return "Resetting"
        case .Unsupported: return "Unsupported"
        case .Unauthorized: return "Unauthorized"
        case .PoweredOff: return "PoweredOff"
        case .PoweredOn: return "PoweredOn"
        }
    }
}

/// BLEScanner implaments the secure BLE session between mobile devices and SID. The communication manager can only send / receive
/// messages over a secure BLE connection, i.e. a valid session context must exist.
public class BLEScanner: NSObject, DataTransfer, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    /// delegate for message tranfer
    weak var delegate: DataTransferDelegate?
    /// connection state default false
    var isConnected = false
    /// if central manager powered on
    var centralManagerPoweredOn : Bool!
    /// Device id as String
    private var deviceId = "EF82084D-BFAD-4ABE-90EE-2552C20C5765"
    /// Device id as String
    private var serviceId = "d1cf0603-b501-4569-a4b9-e47ad3f628a5"
    /// notify characteristic id as String
    private var notifyCharacteristicId = "d1d7a6b6-457e-458a-b237-a9df99b3d98b"
    /// write characteristic id as String
    private var writeCharacteristicId = "c8e58f23-9417-41c6-97a8-70f6b2c8cab9"
    /// the saved SIDs list, manager did found
    private var sids = Set<SID>()
    /// Timer to filter old SIDs
    private var filterTimer: NSTimer?
    /// central mananger object defined in Core Bluetooth
    var centralManager: CBCentralManager!
    /// Peripheral object defined in core bluetooth
    public var sidPeripheral: CBPeripheral?
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
        filterTimer = NSTimer.scheduledTimerWithTimeInterval(1.31, target: self, selector: #selector(BLEScanner.shouldFilterOldSidIds), userInfo: nil, repeats: true)
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
    public func isPoweredOn() -> Bool {
        //print("central manager has \(self.centralManager!.state.description)")
        return self.centralManager!.state == .PoweredOn
    }
    
    /**
     The central manager connect to connected periheral
     
     - parameter sidId: the sidId as String that current peripheral has
     */
    func connectToSidWithId(sidId: String) {
        if let sid = self.sids.filter({$0.sidID.lowercaseString == sidId.stringByReplacingOccurrencesOfString("-", withString: "").lowercaseString}).first {
            print("connecting to sid:\(sid.sidID)")
            self.connectingdSid = sid
            self.sidPeripheral = sid.peripheral!
            self.centralManager.connectPeripheral(sid.peripheral!, options: nil)
        }
    }
    
    /**
     Disconnect peripheral if it was connected, and resetting local saved
     */
    func disconnect() {
        if let peripheral = self.sidPeripheral {
            print("BLE will be disconnected at: \(CACurrentMediaTime())")
            self.centralManager.cancelPeripheralConnection(peripheral)
        }
        self.cleanUpSIDs()
    }
    
    /**
     Sending data to current connected peripheral
     
     - parameter data: NSData that will be sended to SID
     */
    func sendData(data: NSData) {
        if let characteristic = self.writeCharacteristic, peripheral = self.sidPeripheral {
            peripheral.writeValue(data, forCharacteristic: characteristic, type: CBCharacteristicWriteType.WithResponse)
            //self.delegate?.didSendData(self, data: NSData())
        }
    }
    
    /**
     Start BLE-Scanner to scan perihperals with allowing duplicatesKey options
     */
    func begineToScan() {
        self.centralManager.scanForPeripheralsWithServices(nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: 1])
    }
    
    //MARK: - Helper
    /**
     To empty (reset) all local saved SIDs
     */
    private func cleanUpSIDs() {
        sids = Set<SID>()
    }
    
    /**
     Reset current peripheral
     */
    private func resetPeripheral() {
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
    public func centralManagerDidUpdateState(central: CBCentralManager) {
        consoleLog("Central updated state: \(central.state.description)")
        
        self.centralManagerPoweredOn = central.state == CBCentralManagerState.PoweredOn
        if central.state != CBCentralManagerState.PoweredOn {
            //self.cleanUpSIDs()
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
    public func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        guard let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? NSData else {
            return
        }
        let sidID = manufacturerData.toHexString()
        let foundSid = SID(sidID: sidID, peripheral: peripheral, discoveryDate: NSDate(), isConnected: false)
        self.sids.insert(foundSid)
        self.delegate?.transferDidDiscoveredSidId(self, newSid:foundSid)
    }
    
    /**
     See CBCentralManager documentation from coreBluetooth
     */
    public func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        consoleLog("Central failed connecting to peripheral: \(error?.localizedDescription ?? "Unkown error")")
        
        print(error!.description)
        self.cleanUpSIDs()
        self.resetPeripheral()
    }
    
    /**
     See CBCentralManager documentation from coreBluetooth
     */
    public func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        consoleLog("Central connected to peripheral: \(peripheral.identifier.UUIDString)")
        
        self.isConnected = true
        self.sidPeripheral = peripheral
        //print("Peripheral did Connected")
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: self.serviceId)])
    }
    
    /**
     See CBCentralManager documentation from coreBluetooth
     */
    public func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        consoleLog("Central disconnected from peripheral: \(peripheral.identifier.UUIDString)")
        
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
    public func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        if error != nil {
            print("Error: \(error!.description)")
            self.cleanUpSIDs()
            self.resetPeripheral()
        } else {
            for service in peripheral.services! {
                peripheral.discoverCharacteristics([CBUUID(string: self.writeCharacteristicId), CBUUID(string: self.notifyCharacteristicId)], forService: service )
            }
        }
    }
    
    /**
     See CBPeripharalDelegate documentation from coreBluetooth
     */
    public func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if error != nil {
            print("Error: \(error!.description)")
            self.cleanUpSIDs()
            self.resetPeripheral()
        } else {
            for characteristic in service.characteristics! {
                if characteristic.UUID == CBUUID(string: self.notifyCharacteristicId) {
                    self.notifyCharacteristic = characteristic
                    peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                } else if characteristic.UUID == CBUUID(string: self.writeCharacteristicId) {
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
    public func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if characteristic == self.notifyCharacteristic {
            //            print("Received Package at time: \(CACurrentMediaTime())")
            self.delegate?.transferDidReceivedData(self, data: characteristic.value!)
        }
    }
    
    /**
     See CBPeripharalDelegate documentation from coreBluetooth
     */
    public func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        //        print("Did send Package at time: \(CACurrentMediaTime())")
        self.delegate?.transferDidSendData(self, data: NSData())
    }
}

