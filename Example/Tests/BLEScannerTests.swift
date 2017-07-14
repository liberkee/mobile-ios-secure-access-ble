//
//  BLEScannerTests.swift
//  SecureAccessBLE
//
//  Created by Torsten Lehmann on 14.07.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import XCTest
@testable import SecureAccessBLE
import CoreBluetooth

class CBCentralManagerMock: CBCentralManagerType {

    weak var delegate: CBCentralManagerDelegate?

    var state: CBManagerState = .unknown

    var connectCalledWithPeripheral: CBPeripheralType?
    func connect(_ peripheral: CBPeripheralType, options _: [String: Any]?) {
        connectCalledWithPeripheral = peripheral
    }

    var cancelConnectionCalledWithPeripheral: CBPeripheralType?
    func cancelPeripheralConnection(_ peripheral: CBPeripheralType) {
        cancelConnectionCalledWithPeripheral = peripheral
    }

    var scanForPeripheralsCalledWithArguments: (serviceUUIDs: [CBUUID]?, options: [String: Any]?)
    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String: Any]?) {
        scanForPeripheralsCalledWithArguments = (serviceUUIDs: serviceUUIDs, options: options)
    }
}

class CBPeripheralMock: CBPeripheralType {

    weak var delegate: CBPeripheralDelegate?

    var services: [CBService]?

    var identifier = UUID()

    func discoverServices(_: [CBUUID]?) {
    }

    func discoverCharacteristics(_: [CBUUID]?, for _: CBService) {
    }

    var writeValueCalledWithArguments: (data: Data, characteristic: CBCharacteristicType, type: CBCharacteristicWriteType)?
    func writeValue(_ data: Data, for characteristic: CBCharacteristicType, type: CBCharacteristicWriteType) {
        writeValueCalledWithArguments = (data: data, characteristic: characteristic, type: type)
    }

    func setNotifyValue(_: Bool, for _: CBCharacteristic) {}
}

class CBServiceMock: CBServiceType {

    var characteristics: [CBCharacteristic]?
}

class CBCharacteristicMock: CBCharacteristicType {

    var uuid: CBUUID = CBUUID()
    var value: Data?
}

class DataTransferDelegateMock: DataTransferDelegate {
    func transferDidSendData(_: DataTransfer, data _: Data) {}

    func transferDidReceivedData(_: DataTransfer, data _: Data) {}

    var calledTransferDidChangedConnectionStateWithIsConnected: Bool?
    func transferDidChangedConnectionState(_: DataTransfer, isConnected: Bool) {
        calledTransferDidChangedConnectionStateWithIsConnected = isConnected
    }

    func transferDidDiscoveredSidId(_: DataTransfer, newSid _: SID) {}

    func transferDidConnectSid(_: DataTransfer, sid _: SID) {}

    func transferDidFailToConnectSid(_: DataTransfer, sid _: SID, error _: Error?) {}
}

class BLEScannerTests: XCTestCase {

    //    override func setUp() {
    //        super.setUp()
    //        // Put setup code here. This method is called before the invocation of each test method in the class.
    //    }
    //
    //    override func tearDown() {
    //        // Put teardown code here. This method is called after the invocation of each test method in the class.
    //        super.tearDown()
    //    }

    func test_isPoweredOn_ifCentralManagerIsPoweredOn_returnsTrue() {

        // Given
        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)

        centralManager.state = .poweredOn

        // Then
        XCTAssertTrue(scanner.isPoweredOn())
    }

    func test_isPoweredOn_ifCentralManagerIsNotPoweredOn_returnsFalse() {

        // Given
        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)

        centralManager.state = .poweredOff

        // Then
        XCTAssertFalse(scanner.isPoweredOn())
    }

    func test_connectToSorc_ifSorcPeripheralIsSet_connectingSidIsSetAndItTriesToConnectToPeripheral() {

        // Given
        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        let sorc = SID(sidID: "id", peripheral: peripheral, discoveryDate: Date(), isConnected: false, rssi: 0)

        // When
        scanner.connectToSorc(sorc)

        // Then
        XCTAssertEqual(scanner.connectingdSid, sorc)
        XCTAssertTrue(centralManager.connectCalledWithPeripheral === peripheral)
    }

    func test_connectToSorc_ifSorcPeripheralIsNotSet_connectingSidIsNotSetAndItDoesNotTryToConnectToAPeripheral() {

        // Given
        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)
        let sorc = SID(sidID: "id", peripheral: nil, discoveryDate: Date(), isConnected: false, rssi: 0)

        // When
        scanner.connectToSorc(sorc)

        // Then
        XCTAssertNil(scanner.connectingdSid)
        XCTAssertNil(centralManager.connectCalledWithPeripheral)
    }

    func test_disconnect_ifSidPeripheralExists_itCancelsTheConnectionToThisPeripheral() {

        // Given
        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        scanner.sidPeripheral = peripheral

        // When
        scanner.disconnect()

        // Then
        XCTAssertTrue(centralManager.cancelConnectionCalledWithPeripheral === peripheral)
    }

    func test_sendData_ifWriteCharacteristicExistsAndSidPeripheralExists_itWritesTheDataToThePeripheralWithResponse() {

        // Given
        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)
        scanner.writeCharacteristic = CBCharacteristicMock()
        let peripheral = CBPeripheralMock()
        scanner.sidPeripheral = peripheral
        let data = Data(bytes: [42])

        // When
        scanner.sendData(data)

        // Then
        let arguments = peripheral.writeValueCalledWithArguments
        XCTAssertEqual(arguments?.data, data)
        XCTAssertEqual(arguments?.type, CBCharacteristicWriteType.withResponse)
    }

    func test_sendData_ifWriteCharacteristicDoesNotExist_itDoesNotWriteTheDataToThePeripheral() {

        // Given
        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)
        scanner.writeCharacteristic = nil
        let peripheral = CBPeripheralMock()
        scanner.sidPeripheral = peripheral
        let data = Data(bytes: [42])

        // When
        scanner.sendData(data)

        // Then
        XCTAssertNil(peripheral.writeValueCalledWithArguments)
    }

    func test_centralManagerDidUpdateState_callsBLEScannerDelegateDidUpdateState() {

        // Given
        class BLEScannerDelegateMock: BLEScannerDelegate {
            var didUpdateStateCalled = false
            func didUpdateState() {
                didUpdateStateCalled = true
            }
        }

        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)
        let delegate = BLEScannerDelegateMock()
        scanner.bleScannerDelegate = delegate

        // When
        scanner.centralManagerDidUpdateState(centralManager)

        // Then
        XCTAssertTrue(delegate.didUpdateStateCalled)
    }

    func test_centralManagerDidUpdateState_ifCentralManagerIsNotPoweredOn_setsSidPeripheralAndConnectingSidToNil() {

        // Given
        let centralManager = CBCentralManagerMock()
        centralManager.state = .poweredOff
        let scanner = BLEScanner(centralManager: centralManager)
        scanner.sidPeripheral = CBPeripheralMock()
        scanner.connectingdSid = SID(sidID: "id", peripheral: nil, discoveryDate: Date(), isConnected: false, rssi: 0)

        // When
        scanner.centralManagerDidUpdateState(centralManager)

        // Then
        XCTAssertNil(scanner.sidPeripheral)
        XCTAssertNil(scanner.connectingdSid)
    }

    func test_centralManagerDidUpdateState_ifCentralManagerIsNotPoweredOn_setsIsConnectedToFalse() {

        // Given
        let centralManager = CBCentralManagerMock()
        centralManager.state = .poweredOff
        let scanner = BLEScanner(centralManager: centralManager)
        scanner.isConnected = true

        // When
        scanner.centralManagerDidUpdateState(centralManager)

        // Then
        XCTAssertFalse(scanner.isConnected)
    }

    func test_centralManagerDidUpdateState_ifCentralManagerIsNotPoweredOn_callsDelegateTransferDidChangedConnectionStateWithIsConnectedFalse() {

        // Given
        let centralManager = CBCentralManagerMock()
        centralManager.state = .poweredOff
        let scanner = BLEScanner(centralManager: centralManager)
        let delegate = DataTransferDelegateMock()
        scanner.delegate = delegate

        // When
        scanner.centralManagerDidUpdateState(centralManager)

        // Then
        XCTAssertFalse(delegate.calledTransferDidChangedConnectionStateWithIsConnected!)
    }

    func test_centralManagerDidUpdateState_ifCentralManagerIsPoweredOn_callsDelegateTransferDidChangedConnectionStateWithCurrentIsConnected() {

        // Given
        let centralManager = CBCentralManagerMock()
        centralManager.state = .poweredOn
        let scanner = BLEScanner(centralManager: centralManager)
        let currentIsConnected = scanner.isConnected
        let delegate = DataTransferDelegateMock()
        scanner.delegate = delegate

        // When
        scanner.centralManagerDidUpdateState(centralManager)

        // Then
        XCTAssertEqual(delegate.calledTransferDidChangedConnectionStateWithIsConnected!, currentIsConnected)
    }

    func test_centralManagerDidUpdateState_ifCentralManagerIsPoweredOn_itScansForPeripheralsAllowingDuplicates() {

        // Given
        let centralManager = CBCentralManagerMock()
        centralManager.state = .poweredOn
        let scanner = BLEScanner(centralManager: centralManager)
        let delegate = DataTransferDelegateMock()
        scanner.delegate = delegate

        // When
        scanner.centralManagerDidUpdateState(centralManager)

        // Then
        let arguments = centralManager.scanForPeripheralsCalledWithArguments
        XCTAssertNil(arguments.serviceUUIDs)
        XCTAssertTrue(arguments.options![CBCentralManagerScanOptionAllowDuplicatesKey] as! Int == 1)
    }
}
