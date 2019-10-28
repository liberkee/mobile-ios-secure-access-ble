//
//  CBWrapper.swift
//  SecureAccessBLE
//
//  Created on 02.08.17.
//  Copyright © 2018 Huf Secure Mobile GmbH. All rights reserved.
//

import CoreBluetooth
import Foundation

protocol CBCentralManagerType: class {
    var delegate: CBCentralManagerDelegate? { get set }

    var state: CBManagerState { get }

    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String: Any]?)

    func stopScan()

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
    var delegate: CBPeripheralDelegate? { get set }

    var services_: [CBServiceType]? { get }

    var identifier: UUID { get }

    func discoverServices(_ serviceUUIDs: [CBUUID]?)

    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBServiceType)

    func writeValue(_ data: Data, for characteristic: CBCharacteristicType, type: CBCharacteristicWriteType)

    func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int

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
