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

class SystemClockMock: SystemClockType {

    var currentNow: Date

    init(currentNow: Date) {
        self.currentNow = currentNow
    }

    func now() -> Date {
        return currentNow
    }
}

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

    var discoverServicesCalledWithUUIDs: [CBUUID]?
    func discoverServices(_ serviceUUIDs: [CBUUID]?) {
        discoverServicesCalledWithUUIDs = serviceUUIDs
    }

    var discoverCharacteristicsCalledWithArguments: (characteristicUUIDs: [CBUUID]?, service: CBServiceType)?
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBServiceType) {
        discoverCharacteristicsCalledWithArguments = (characteristicUUIDs, service)
    }

    var writeValueCalledWithArguments: (data: Data, characteristic: CBCharacteristicType, type: CBCharacteristicWriteType)?
    func writeValue(_ data: Data, for characteristic: CBCharacteristicType, type: CBCharacteristicWriteType) {
        writeValueCalledWithArguments = (data: data, characteristic: characteristic, type: type)
    }

    var setNotifyValueCalledWithArguments: (enabled: Bool, characteristic: CBCharacteristicType)?
    func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristicType) {
        setNotifyValueCalledWithArguments = (enabled, characteristic)
    }
}

class CBServiceMock: CBServiceType {

    var characteristics_: [CBCharacteristicType]?
}

class CBCharacteristicMock: CBCharacteristicType {

    var uuid: CBUUID = CBUUID()
    var value: Data?
}

class DataTransferDelegateMock: DataTransferDelegate {

    var transferDidSendDataCalled = false
    func transferDidSendData(_: DataTransfer) {
        transferDidSendDataCalled = true
    }

    var transferDidReceivedDataCalledWithData: Data?
    func transferDidReceivedData(_: DataTransfer, data: Data) {
        transferDidReceivedDataCalledWithData = data
    }
}

extension BLEScanner {

    convenience init(centralManager: CBCentralManagerType) {
        self.init(centralManager: centralManager, systemClock: SystemClock())
    }
}

class BLEScannerTests: XCTestCase {

    let notifyCharacteristicId = "d1d7a6b6-457e-458a-b237-a9df99b3d98b"
    let writeCharacteristicId = "c8e58f23-9417-41c6-97a8-70f6b2c8cab9"
    let serviceId = "d1cf0603-b501-4569-a4b9-e47ad3f628a5"

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

        // When
        scanner.centralManagerDidUpdateState_(centralManager)

        // Then
        let arguments = centralManager.scanForPeripheralsCalledWithArguments
        XCTAssertNil(arguments.serviceUUIDs)
        XCTAssertTrue(arguments.options![CBCentralManagerScanOptionAllowDuplicatesKey] as! Int == 1)
    }

    func test_centralManagerDidUpdateState_ifCentralManagerIsNotPoweredOn_itResetsDiscoveredSorcs() {

        // Given
        let centralManager = CBCentralManagerMock()
        centralManager.state = .poweredOn
        let scanner = BLEScanner(centralManager: centralManager)

        let peripheral = CBPeripheralMock()
        prepareDiscoveredSorc("1a", peripheral: peripheral, scanner: scanner, centralManager: centralManager)

        var discoveryChange: DiscoveryChange?
        _ = scanner.discoveryChange.subscribeNext { change in
            discoveryChange = change
        }

        // When
        centralManager.state = .poweredOff
        scanner.centralManagerDidUpdateState_(centralManager)

        // Then
        XCTAssert(discoveryChange!.state.isEmpty)
        if case .sorcsReset = discoveryChange!.action {} else {
            XCTFail()
        }
    }

    func test_centralManagerDidDiscoverPeripheral_ifManufacturerDataKeyIsSet_addsSorcToDiscoveredSorcs() {

        // Given
        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)

        let sorcID = "1a"
        let peripheral = CBPeripheralMock()

        let advertisementData: [String: Any] = [
            CBAdvertisementDataManufacturerDataKey: sorcID.dataFromHexadecimalString()!,
        ]

        var discoveryChange: DiscoveryChange?
        _ = scanner.discoveryChange.subscribeNext { change in
            discoveryChange = change
        }

        // When
        scanner.centralManager_(centralManager, didDiscover: peripheral, advertisementData: advertisementData, rssi: 0)

        // Then
        XCTAssert(discoveryChange!.state.contains("1a"))
        if case let .sorcDiscovered(discoveredSorcID) = discoveryChange!.action {
            XCTAssertEqual(discoveredSorcID, "1a")
        } else {
            XCTFail()
        }
    }

    func test_centralManagerDidDiscoverPeripheral_ifManufacturerDataKeyIsNotSet_doesNotUpdateDiscoveredSorcs() {

        // Given
        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)

        let peripheral = CBPeripheralMock()
        let advertisementData = [String: Any]()

        var discoveryChange: DiscoveryChange?
        _ = scanner.discoveryChange.subscribeNext { change in
            discoveryChange = change
        }

        // When
        scanner.centralManager_(centralManager, didDiscover: peripheral, advertisementData: advertisementData, rssi: 0)

        // Then
        if case .initial = discoveryChange!.action {} else {
            XCTFail()
        }
    }

    func test_centralManagerDidConnectPeripheral_ifItsConnectingAndPeripheralIsDiscovered_triesToDiscoverServicesOfPeripheral() {

        // Given
        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)

        let peripheral = CBPeripheralMock()

        prepareConnectingSorc("1a", peripheral: peripheral, scanner: scanner, centralManager: centralManager)

        // When
        scanner.centralManager_(centralManager, didConnect: peripheral)

        // Then
        XCTAssertEqual(peripheral.discoverServicesCalledWithUUIDs!, [CBUUID(string: serviceId)])
    }

    func test_centralManagerDidConnectPeripheral_ifItsNotConnecting_doesNotTryToDiscoverServices() {

        // Given
        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)

        let peripheral = CBPeripheralMock()

        // When
        scanner.centralManager_(centralManager, didConnect: peripheral)

        // Then
        XCTAssertNil(peripheral.discoverServicesCalledWithUUIDs)
    }

    func test_centralManagerDidFailToConnect_ifItsConnectingAndPeripheralIsDiscovered_connectionStateDisconnected() {

        // Given
        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)

        let peripheral = CBPeripheralMock()

        prepareConnectingSorc("1a", peripheral: peripheral, scanner: scanner, centralManager: centralManager)

        // When
        scanner.centralManager_(centralManager, didFailToConnect: peripheral, error: nil)

        // Then
        if case .disconnected = scanner.connectionState.value {} else {
            XCTFail()
        }
    }

    func test_centralManagerDidFailToConnect_ifItsNotConnecting_connectionStateNotUpdated() {

        // Given
        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)

        let peripheral = CBPeripheralMock()

        prepareConnectedSorc("1a", peripheral: peripheral, scanner: scanner, centralManager: centralManager)

        // When
        scanner.centralManager_(centralManager, didFailToConnect: peripheral, error: nil)

        // Then
        if case .connected = scanner.connectionState.value {} else {
            XCTFail()
        }
    }

    func test_centralManagerDidDisconnectPeripheral_ifItsConnected_removesDiscoveredSorcAndConnectionStateDisconnected() {

        // Given
        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)

        let peripheral = CBPeripheralMock()

        prepareConnectedSorc("1a", peripheral: peripheral, scanner: scanner, centralManager: centralManager)

        var discoveryChange: DiscoveryChange?
        _ = scanner.discoveryChange.subscribeNext { change in
            discoveryChange = change
        }

        // When
        scanner.centralManager_(centralManager, didDisconnectPeripheral: peripheral, error: nil)

        // Then
        if case let .sorcDisconnected(disconnectedSorcID) = discoveryChange!.action {
            XCTAssertEqual(disconnectedSorcID, "1a")
        } else {
            XCTFail()
        }
        if case .disconnected = scanner.connectionState.value {} else {
            XCTFail()
        }
    }

    func test_centralManagerDidDisconnectPeripheral_ifItsNotConnected_doesNothing() {

        // Given
        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)

        let peripheral = CBPeripheralMock()

        prepareConnectingSorc("1a", peripheral: peripheral, scanner: scanner, centralManager: centralManager)

        var discoveryChange: DiscoveryChange?
        _ = scanner.discoveryChange.subscribeNext { change in
            discoveryChange = change
        }

        // When
        scanner.centralManager_(centralManager, didDisconnectPeripheral: peripheral, error: nil)

        // Then
        if case .sorcDisconnected = discoveryChange!.action {
            XCTFail()
        }
        if case .connecting = scanner.connectionState.value {} else {
            XCTFail()
        }
    }

    func test_peripheralDidDiscoverServices_ifItsConnectingAndPeripheralIsDiscoveredAndErrorIsNil_triesToDiscoverCharacteristicsForService() {

        // Given
        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        let service = CBServiceMock()
        peripheral.services_ = [service]

        prepareConnectingSorc("1a", peripheral: peripheral, scanner: scanner, centralManager: centralManager)

        // When
        scanner.peripheral_(peripheral, didDiscoverServices: nil)

        // Then
        if let arguments = peripheral.discoverCharacteristicsCalledWithArguments {
            XCTAssert(arguments.characteristicUUIDs!.contains(CBUUID(string: writeCharacteristicId)))
            XCTAssert(arguments.characteristicUUIDs!.contains(CBUUID(string: notifyCharacteristicId)))
        } else {
            XCTFail()
        }
    }

    func test_peripheralDidDiscoverServices_ifItsConnectingAndPeripheralIsDiscoveredAndErrorExists_disconnects() {

        // Given
        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        let service = CBServiceMock()
        peripheral.services_ = [service]

        prepareConnectingSorc("1a", peripheral: peripheral, scanner: scanner, centralManager: centralManager)

        // When
        scanner.peripheral_(peripheral, didDiscoverServices: NSError(domain: "", code: 0, userInfo: nil))

        // Then
        if case .disconnected = scanner.connectionState.value {} else {
            XCTFail()
        }
    }

    func test_peripheralDidDiscoverCharacteristics_ifItsConnectingAndPeripheralIsDiscoveredAndErrorIsNil_connectedAndSetNotifyValue() {

        // Given
        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        let service = CBServiceMock()
        peripheral.services_ = [service]

        let writeCharacteristic = CBCharacteristicMock()
        writeCharacteristic.uuid = CBUUID(string: writeCharacteristicId)
        let notifyCharacteristic = CBCharacteristicMock()
        notifyCharacteristic.uuid = CBUUID(string: notifyCharacteristicId)
        service.characteristics_ = [writeCharacteristic, notifyCharacteristic]

        prepareConnectingSorc("1a", peripheral: peripheral, scanner: scanner, centralManager: centralManager)

        // When
        scanner.peripheral_(peripheral, didDiscoverCharacteristicsFor: service, error: nil)

        // Then
        if case let .connected(sorcID) = scanner.connectionState.value {
            XCTAssertEqual(sorcID, "1a")
        } else {
            XCTFail()
        }
        if let arguments = peripheral.setNotifyValueCalledWithArguments {
            XCTAssert(arguments.enabled)
            XCTAssertEqual(arguments.characteristic.uuid, notifyCharacteristic.uuid)
        } else {
            XCTFail()
        }
    }

    func test_peripheralDidDiscoverCharacteristics_ifItsConnectingAndPeripheralIsDiscoveredAndErrorExists_disconnects() {

        // Given
        let centralManager = CBCentralManagerMock()
        let scanner = BLEScanner(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        let service = CBServiceMock()
        peripheral.services_ = [service]

        prepareConnectingSorc("1a", peripheral: peripheral, scanner: scanner, centralManager: centralManager)

        // When
        scanner.peripheral_(peripheral, didDiscoverCharacteristicsFor: service, error: NSError(domain: "", code: 0, userInfo: nil))

        // Then
        if case .disconnected = scanner.connectionState.value {} else {
            XCTFail()
        }
    }

    func test_peripheralDidUpdateValue_ifNotifyCharacteristic_callsTransferDidReceivedData() {

        // Given
        let centralManager = CBCentralManagerMock()
        let transferDelegate = DataTransferDelegateMock()
        let scanner = BLEScanner(centralManager: centralManager)
        scanner.delegate = transferDelegate
        let notifyCharacteristic = CBCharacteristicMock()
        notifyCharacteristic.value = Data(base64Encoded: "data")
        notifyCharacteristic.uuid = CBUUID(string: notifyCharacteristicId)

        // When
        scanner.peripheral_(CBPeripheralMock(), didUpdateValueFor: notifyCharacteristic, error: nil)

        // Then
        XCTAssertEqual(transferDelegate.transferDidReceivedDataCalledWithData, Data(base64Encoded: "data"))
    }

    func test_peripheralDidWriteValue_callsTransferDidSendData() {

        // Given
        let centralManager = CBCentralManagerMock()
        let transferDelegate = DataTransferDelegateMock()
        let scanner = BLEScanner(centralManager: centralManager)
        scanner.delegate = transferDelegate

        // When
        scanner.peripheral_(CBPeripheralMock(), didWriteValueFor: CBCharacteristicMock(), error: nil)

        // Then
        XCTAssert(transferDelegate.transferDidSendDataCalled)
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
