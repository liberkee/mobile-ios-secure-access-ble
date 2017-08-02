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

    var calledTransferDidChangedConnectionStateWithState: TransferConnectionState?
    func transferDidChangedConnectionState(_: DataTransfer, state: TransferConnectionState) {
        calledTransferDidChangedConnectionStateWithState = state
    }

    func transferDidDiscoveredSidId(_: DataTransfer, newSid _: SID) {}

    func transferDidConnectSid(_: DataTransfer, sid _: SID) {}

    func transferDidFailToConnectSid(_: DataTransfer, sid _: SID, error _: Error?) {}
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

    func test_connectToSorc_ifSorcPeripheralIsNotSet_itDoesNotMoveToConnectingStateAndItDoesNotTryToConnectToAPeripheral() {

        // Given
        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)
        let sorc = SID(sidID: "id", peripheral: nil)

        // When
        scanner.connectToSorc(sorc)

        // Then
        if case .connecting = scanner.connectionState {
            XCTFail()
        }
        XCTAssertNil(centralManager.connectCalledWithPeripheral)
    }

    func test_connectToSorc_ifDisconnected_itMovesToConnectingStateAndItTriesToConnectToPeripheral() {

        // Given
        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        let sorc = SID(sidID: "id", peripheral: peripheral)

        // When
        scanner.connectToSorc(sorc)

        // Then
        if case let .connecting(connectingSorc) = scanner.connectionState {
            XCTAssertEqual(connectingSorc, sorc)
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
        let sorc = SID(sidID: "id", peripheral: peripheral)
        scanner.connectToSorc(sorc)
        centralManager.connectCalledWithPeripheral = nil

        // When
        scanner.connectToSorc(sorc)

        // Then
        if case let .connecting(connectingSorc) = scanner.connectionState {
            XCTAssertEqual(connectingSorc, sorc)
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
        let sorc1 = SID(sidID: "id1", peripheral: peripheral1)
        scanner.connectToSorc(sorc1)
        centralManager.connectCalledWithPeripheral = nil

        let peripheral2 = CBPeripheralMock()
        let sorc2 = SID(sidID: "id2", peripheral: peripheral2)

        // When
        scanner.connectToSorc(sorc2)

        // Then
        if case let .connecting(connectingSorc) = scanner.connectionState {
            XCTAssertEqual(connectingSorc, sorc2)
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
        let sorc = SID(sidID: "id", peripheral: peripheral)
        prepareBeingConnectedToSorc(sorc, scanner: scanner, centralManager: centralManager)

        // When
        scanner.connectToSorc(sorc)

        // Then
        if case let .connected(connectedSorc) = scanner.connectionState {
            XCTAssertEqual(connectedSorc, sorc)
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
        let sorc1 = SID(sidID: "id1", peripheral: peripheral1)
        prepareBeingConnectedToSorc(sorc1, scanner: scanner, centralManager: centralManager)

        let peripheral2 = CBPeripheralMock()
        let sorc2 = SID(sidID: "id2", peripheral: peripheral2)

        // When
        scanner.connectToSorc(sorc2)

        // Then
        XCTAssertEqual(centralManager.cancelConnectionCalledWithPeripheral?.identifier, peripheral1.identifier)
        if case let .connecting(connectingSorc) = scanner.connectionState {
            XCTAssertEqual(connectingSorc, sorc2)
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
        let sorc = SID(sidID: "id", peripheral: peripheral)
        scanner.connectToSorc(sorc)

        // When
        scanner.disconnect()

        // Then
        XCTAssertEqual(centralManager.cancelConnectionCalledWithPeripheral?.identifier, peripheral.identifier)
        if case .disconnected = scanner.connectionState {} else {
            XCTFail()
        }
    }

    func test_disconnect_ifItsConnected_itCancelsTheConnectionAndMovesToDisconnectedState() {

        // Given
        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        let sorc = SID(sidID: "id", peripheral: peripheral)
        prepareBeingConnectedToSorc(sorc, scanner: scanner, centralManager: centralManager)

        // When
        scanner.disconnect()

        // Then
        XCTAssertEqual(centralManager.cancelConnectionCalledWithPeripheral?.identifier, peripheral.identifier)
        if case .disconnected = scanner.connectionState {} else {
            XCTFail()
        }
    }

    func test_sendData_ifItsConnected_itWritesTheDataToThePeripheralWithResponse() {

        // Given
        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        let sorc = SID(sidID: "id", peripheral: peripheral)
        prepareBeingConnectedToSorc(sorc, scanner: scanner, centralManager: centralManager)
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
        scanner.centralManagerDidUpdateState_(centralManager)

        // Then
        XCTAssertTrue(delegate.didUpdateStateCalled)
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

    private func prepareBeingConnectedToSorc(_ sorc: SID, scanner: BLEScanner, centralManager: CBCentralManagerMock) {
        let peripheral = sorc.peripheral as! CBPeripheralMock
        scanner.connectToSorc(sorc)
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

private extension SID {

    init(sidID: String, peripheral: CBPeripheralType?) {
        self.init(sidID: sidID, peripheral: peripheral, discoveryDate: Date(), isConnected: false, rssi: 0)
    }
}
