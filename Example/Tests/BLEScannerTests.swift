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

    var services_: [CBServiceType]?

    var identifier = UUID()

    func discoverServices(_: [CBUUID]?) {
    }

    func discoverCharacteristics(_: [CBUUID]?, for _: CBServiceType) {
    }

    var writeValueCalledWithArguments: (data: Data, characteristic: CBCharacteristicType, type: CBCharacteristicWriteType)?
    func writeValue(_ data: Data, for characteristic: CBCharacteristicType, type: CBCharacteristicWriteType) {
        writeValueCalledWithArguments = (data: data, characteristic: characteristic, type: type)
    }

    func setNotifyValue(_: Bool, for _: CBCharacteristicType) {}
}

class CBServiceMock: CBServiceType {

    var characteristics_: [CBCharacteristicType]?
}

class CBCharacteristicMock: CBCharacteristicType {

    var uuid: CBUUID = CBUUID()
    var value: Data?
}

class DataTransferDelegateMock: DataTransferDelegate {
    func transferDidSendData(_: DataTransfer, data _: Data) {}

    func transferDidReceivedData(_: DataTransfer, data _: Data) {}
}

class BLEScannerTests: XCTestCase {

    let notifyCharacteristicId = "d1d7a6b6-457e-458a-b237-a9df99b3d98b"
    let writeCharacteristicId = "c8e58f23-9417-41c6-97a8-70f6b2c8cab9"

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
        centralManager.state = .poweredOn
        let scanner = BLEScanner(centralManager: centralManager)

        // Then
        XCTAssertTrue(scanner.isPoweredOn.value)
    }

    func test_isPoweredOn_ifCentralManagerIsNotPoweredOn_returnsFalse() {

        // Given
        let centralManager = CBCentralManagerMock()
        centralManager.state = .poweredOff
        let scanner = BLEScanner(centralManager: centralManager)

        // Then
        XCTAssertFalse(scanner.isPoweredOn.value)
    }

    func test_connectToSorc_ifSorcIsNotDiscovered_itDoesNotMoveToConnectingStateAndItDoesNotTryToConnectToAPeripheral() {

        // Given
        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)

        // When
        scanner.connectToSorc("1a")

        // Then
        if case .connecting = scanner.connectionState.value {
            XCTFail()
        }
        XCTAssertNil(centralManager.connectCalledWithPeripheral)
    }

    func test_connectToSorc_ifDisconnected_itMovesToConnectingStateAndItTriesToConnectToPeripheral() {

        // Given
        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        prepareDiscoveredSorc("1a", peripheral: peripheral, scanner: scanner, centralManager: centralManager)

        // When
        scanner.connectToSorc("1a")

        // Then
        if case let .connecting(connectingSorcID) = scanner.connectionState.value {
            XCTAssertEqual(connectingSorcID, "1a")
        } else {
            XCTFail()
        }
        XCTAssertEqual(centralManager.connectCalledWithPeripheral?.identifier, peripheral.identifier)
    }

    func test_connectToSorc_ifConnectingToSameSorc_itStaysInConnectingStateAndItTriesToConnectToPeripheralAgain() {

        // Given
        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        prepareConnectingSorc("1a", peripheral: peripheral, scanner: scanner, centralManager: centralManager)

        // When
        scanner.connectToSorc("1a")

        // Then
        if case let .connecting(connectingSorcID) = scanner.connectionState.value {
            XCTAssertEqual(connectingSorcID, "1a")
        } else {
            XCTFail()
        }
        XCTAssertEqual(centralManager.connectCalledWithPeripheral?.identifier, peripheral.identifier)
    }

    func test_connectToSorc_ifConnectingToOtherSorc_itMovesToConnectingToOtherSorcStateAndItTriesToConnectToOtherPeripheral() {

        // Given
        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)
        let peripheral1 = CBPeripheralMock()
        let sorcID1 = "1a"
        prepareConnectingSorc(sorcID1, peripheral: peripheral1, scanner: scanner, centralManager: centralManager)

        let peripheral2 = CBPeripheralMock()
        let sorcID2 = "1b"
        prepareDiscoveredSorc(sorcID2, peripheral: peripheral2, scanner: scanner, centralManager: centralManager)

        // When
        scanner.connectToSorc(sorcID2)

        // Then
        if case let .connecting(connectingSorcID) = scanner.connectionState.value {
            XCTAssertEqual(connectingSorcID, sorcID2)
        } else {
            XCTFail()
        }
        XCTAssertEqual(centralManager.connectCalledWithPeripheral?.identifier, peripheral2.identifier)
    }

    func test_connectToSorc_ifAlreadyConnectedToSameSorc_itDoesNotConnectAgain() {

        // Given
        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        prepareConnectedSorc("1a", peripheral: peripheral, scanner: scanner, centralManager: centralManager)

        // When
        scanner.connectToSorc("1a")

        // Then
        if case let .connected(connectedSorcID) = scanner.connectionState.value {
            XCTAssertEqual(connectedSorcID, "1a")
        } else {
            XCTFail()
        }
        XCTAssertNil(centralManager.connectCalledWithPeripheral)
    }

    func test_connectToSorc_ifConnectedToAnotherSorc_itDisconnectsFromTheCurrentPeripheralAndTriesToConnectToTheNewPeripheral() {

        // Given
        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)
        let peripheral1 = CBPeripheralMock()
        prepareConnectedSorc("1a", peripheral: peripheral1, scanner: scanner, centralManager: centralManager)

        let peripheral2 = CBPeripheralMock()
        prepareDiscoveredSorc("1b", peripheral: peripheral2, scanner: scanner, centralManager: centralManager)

        // When
        scanner.connectToSorc("1b")

        // Then
        XCTAssertEqual(centralManager.cancelConnectionCalledWithPeripheral?.identifier, peripheral1.identifier)
        if case let .connecting(connectingSorcID) = scanner.connectionState.value {
            XCTAssertEqual(connectingSorcID, "1b")
        } else {
            XCTFail()
        }
        XCTAssertEqual(centralManager.connectCalledWithPeripheral?.identifier, peripheral2.identifier)
    }

    func test_disconnect_ifItsConnecting_itCancelsTheConnectionAndMovesToDisconnectedState() {

        // Given
        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        prepareConnectingSorc("1a", peripheral: peripheral, scanner: scanner, centralManager: centralManager)

        // When
        scanner.disconnect()

        // Then
        XCTAssertEqual(centralManager.cancelConnectionCalledWithPeripheral?.identifier, peripheral.identifier)
        if case .disconnected = scanner.connectionState.value {} else {
            XCTFail()
        }
    }

    func test_disconnect_ifItsConnected_itCancelsTheConnectionAndMovesToDisconnectedState() {

        // Given
        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        prepareConnectedSorc("1a", peripheral: peripheral, scanner: scanner, centralManager: centralManager)

        // When
        scanner.disconnect()

        // Then
        XCTAssertEqual(centralManager.cancelConnectionCalledWithPeripheral?.identifier, peripheral.identifier)
        if case .disconnected = scanner.connectionState.value {} else {
            XCTFail()
        }
    }

    func test_sendData_ifItsConnected_itWritesTheDataToThePeripheralWithResponse() {

        // Given
        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        prepareConnectedSorc("1a", peripheral: peripheral, scanner: scanner, centralManager: centralManager)
        let data = Data(bytes: [42])

        // When
        scanner.sendData(data)

        // Then
        let arguments = peripheral.writeValueCalledWithArguments
        XCTAssertEqual(arguments?.data, data)
        XCTAssertEqual(arguments?.type, CBCharacteristicWriteType.withResponse)
    }

    func test_sendData_ifItsNotConnected_itDoesNotWriteTheDataToThePeripheral() {

        // Given
        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        let data = Data(bytes: [42])

        // When
        scanner.sendData(data)

        // Then
        XCTAssertNil(peripheral.writeValueCalledWithArguments)
    }

    func test_centralManagerDidUpdateState_sendsIsPoweredOnUpdate() {

        // Given
        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)

        var isPoweredOnUpdate: Bool?
        _ = scanner.isPoweredOn.subscribeNext { isPoweredOn in
            isPoweredOnUpdate = isPoweredOn
        }

        // When
        scanner.centralManagerDidUpdateState_(centralManager)

        // Then
        XCTAssertFalse(isPoweredOnUpdate!)
    }

    func test_centralManagerDidUpdateState_ifCentralManagerIsPoweredOn_itScansForPeripheralsAllowingDuplicates() {

        // Given
        let centralManager = CBCentralManagerMock()
        centralManager.state = .poweredOn
        let scanner = BLEScanner(centralManager: centralManager)
        let delegate = DataTransferDelegateMock()
        scanner.delegate = delegate

        // When
        scanner.centralManagerDidUpdateState_(centralManager)

        // Then
        let arguments = centralManager.scanForPeripheralsCalledWithArguments
        XCTAssertNil(arguments.serviceUUIDs)
        XCTAssertTrue(arguments.options![CBCentralManagerScanOptionAllowDuplicatesKey] as! Int == 1)
    }

    private func prepareDiscoveredSorc(_ sorcID: SorcID, peripheral: CBPeripheralType, scanner: BLEScanner, centralManager: CBCentralManagerMock) {
        let advertisementData: [String: Any] = [
            CBAdvertisementDataManufacturerDataKey: sorcID.dataFromHexadecimalString()!,
        ]
        scanner.centralManager_(centralManager, didDiscover: peripheral, advertisementData: advertisementData, rssi: 0)
    }

    private func prepareConnectingSorc(_ sorcID: SorcID, peripheral: CBPeripheralType, scanner: BLEScanner, centralManager: CBCentralManagerMock) {
        prepareDiscoveredSorc(sorcID, peripheral: peripheral, scanner: scanner, centralManager: centralManager)
        scanner.connectToSorc(sorcID)

        centralManager.connectCalledWithPeripheral = nil
    }

    private func prepareConnectedSorc(_ sorcID: SorcID, peripheral: CBPeripheralMock, scanner: BLEScanner, centralManager: CBCentralManagerMock) {
        prepareDiscoveredSorc(sorcID, peripheral: peripheral, scanner: scanner, centralManager: centralManager)
        scanner.connectToSorc(sorcID)
        scanner.centralManager_(centralManager, didConnect: peripheral)

        let service = CBServiceMock()
        peripheral.services_ = [service]
        scanner.peripheral_(peripheral, didDiscoverServices: nil)

        let notifyCharacteristic = CBCharacteristicMock()
        notifyCharacteristic.uuid = CBUUID(string: notifyCharacteristicId)
        let writeCharacteristic = CBCharacteristicMock()
        writeCharacteristic.uuid = CBUUID(string: writeCharacteristicId)
        service.characteristics_ = [notifyCharacteristic, writeCharacteristic]

        scanner.peripheral_(peripheral, didDiscoverCharacteristicsFor: service, error: nil)

        centralManager.connectCalledWithPeripheral = nil
    }
}
