//
//  SorcConnectionManagerTests.swift
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

    func timeIntervalSinceNow(for date: Date) -> TimeInterval {
        return date.timeIntervalSince(currentNow)
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

extension SorcConnectionManager {

    convenience init(centralManager: CBCentralManagerType, createTimer: CreateTimer? = nil) {
        let createTimer: CreateTimer = createTimer ?? { block in
            Timer(timeInterval: 1000, repeats: false, block: { _ in block() })
        }
        self.init(centralManager: centralManager, systemClock: SystemClock(), createTimer: createTimer)
    }
}

class SorcConnectionManagerTests: XCTestCase {

    let notifyCharacteristicId = "d1d7a6b6-457e-458a-b237-a9df99b3d98b"
    let writeCharacteristicId = "c8e58f23-9417-41c6-97a8-70f6b2c8cab9"
    let serviceId = "d1cf0603-b501-4569-a4b9-e47ad3f628a5"

    func test_isPoweredOn_ifCentralManagerIsPoweredOn_returnsTrue() {

        // Given
        let centralManager = CBCentralManagerMock()
        centralManager.state = .poweredOn
        let connectionManager = SorcConnectionManager(centralManager: centralManager)

        // Then
        XCTAssertTrue(connectionManager.isPoweredOn.value)
    }

    func test_isPoweredOn_ifCentralManagerIsNotPoweredOn_returnsFalse() {

        // Given
        let centralManager = CBCentralManagerMock()
        centralManager.state = .poweredOff
        let connectionManager = SorcConnectionManager(centralManager: centralManager)

        // Then
        XCTAssertFalse(connectionManager.isPoweredOn.value)
    }

    func test_connectToSorc_ifSorcIsNotDiscovered_itDoesNotMoveToConnectingStateAndItDoesNotTryToConnectToAPeripheral() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)

        // When
        connectionManager.connectToSorc("1a")

        // Then
        if case .connecting = connectionManager.connectionChange.value.state {
            XCTFail()
        }
        XCTAssertNil(centralManager.connectCalledWithPeripheral)
    }

    func test_connectToSorc_ifDisconnected_itMovesToConnectingStateAndItTriesToConnectToPeripheral() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        prepareDiscoveredSorc("1a", peripheral: peripheral, connectionManager: connectionManager, centralManager: centralManager)

        // When
        connectionManager.connectToSorc("1a")

        // Then
        if case let .connecting(connectingSorcID) = connectionManager.connectionChange.value.state {
            XCTAssertEqual(connectingSorcID, "1a")
        } else {
            XCTFail()
        }
        if case let .connect(connectingSorcID) = connectionManager.connectionChange.value.action {
            XCTAssertEqual(connectingSorcID, "1a")
        } else {
            XCTFail()
        }
        XCTAssertEqual(centralManager.connectCalledWithPeripheral?.identifier, peripheral.identifier)
    }

    func test_connectToSorc_ifConnectingToSameSorc_itStaysInConnectingStateAndItTriesToConnectToPeripheralAgain() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        prepareConnectingSorc("1a", peripheral: peripheral, connectionManager: connectionManager, centralManager: centralManager)

        // When
        connectionManager.connectToSorc("1a")

        // Then
        if case let .connecting(connectingSorcID) = connectionManager.connectionChange.value.state {
            XCTAssertEqual(connectingSorcID, "1a")
        } else {
            XCTFail()
        }
        if case let .connect(connectingSorcID) = connectionManager.connectionChange.value.action {
            XCTAssertEqual(connectingSorcID, "1a")
        } else {
            XCTFail()
        }
        XCTAssertEqual(centralManager.connectCalledWithPeripheral?.identifier, peripheral.identifier)
    }

    func test_connectToSorc_ifConnectingToOtherSorc_itMovesToConnectingToOtherSorcStateAndItTriesToConnectToOtherPeripheral() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)
        let peripheral1 = CBPeripheralMock()
        let sorcID1 = "1a"
        prepareConnectingSorc(sorcID1, peripheral: peripheral1, connectionManager: connectionManager, centralManager: centralManager)

        let peripheral2 = CBPeripheralMock()
        let sorcID2 = "1b"
        prepareDiscoveredSorc(sorcID2, peripheral: peripheral2, connectionManager: connectionManager, centralManager: centralManager)

        // When
        connectionManager.connectToSorc(sorcID2)

        // Then
        if case let .connecting(connectingSorcID) = connectionManager.connectionChange.value.state {
            XCTAssertEqual(connectingSorcID, sorcID2)
        } else {
            XCTFail()
        }
        if case let .connect(connectingSorcID) = connectionManager.connectionChange.value.action {
            XCTAssertEqual(connectingSorcID, sorcID2)
        } else {
            XCTFail()
        }
        XCTAssertEqual(centralManager.connectCalledWithPeripheral?.identifier, peripheral2.identifier)
    }

    func test_connectToSorc_ifAlreadyConnectedToSameSorc_itDoesNotConnectAgain() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        prepareConnectedSorc("1a", peripheral: peripheral, connectionManager: connectionManager, centralManager: centralManager)

        // When
        connectionManager.connectToSorc("1a")

        // Then
        if case let .connected(connectedSorcID) = connectionManager.connectionChange.value.state {
            XCTAssertEqual(connectedSorcID, "1a")
        } else {
            XCTFail()
        }
        if case let .connectionEstablished(connectedSorcID) = connectionManager.connectionChange.value.action {
            XCTAssertEqual(connectedSorcID, "1a")
        } else {
            XCTFail()
        }
        XCTAssertNil(centralManager.connectCalledWithPeripheral)
    }

    func test_connectToSorc_ifConnectedToAnotherSorc_itDisconnectsFromTheCurrentPeripheralAndTriesToConnectToTheNewPeripheral() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)
        let peripheral1 = CBPeripheralMock()
        prepareConnectedSorc("1a", peripheral: peripheral1, connectionManager: connectionManager, centralManager: centralManager)

        let peripheral2 = CBPeripheralMock()
        prepareDiscoveredSorc("1b", peripheral: peripheral2, connectionManager: connectionManager, centralManager: centralManager)

        // When
        connectionManager.connectToSorc("1b")

        // Then
        XCTAssertEqual(centralManager.cancelConnectionCalledWithPeripheral?.identifier, peripheral1.identifier)
        if case let .connecting(connectingSorcID) = connectionManager.connectionChange.value.state {
            XCTAssertEqual(connectingSorcID, "1b")
        } else {
            XCTFail()
        }
        if case let .connect(connectingSorcID) = connectionManager.connectionChange.value.action {
            XCTAssertEqual(connectingSorcID, "1b")
        } else {
            XCTFail()
        }
        XCTAssertEqual(centralManager.connectCalledWithPeripheral?.identifier, peripheral2.identifier)
    }

    func test_disconnect_ifItsConnecting_itCancelsTheConnectionAndMovesToDisconnectedState() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        prepareConnectingSorc("1a", peripheral: peripheral, connectionManager: connectionManager, centralManager: centralManager)

        // When
        connectionManager.disconnect()

        // Then
        XCTAssertEqual(centralManager.cancelConnectionCalledWithPeripheral?.identifier, peripheral.identifier)
        if case .disconnected = connectionManager.connectionChange.value.state {} else {
            XCTFail()
        }
        if case .disconnect = connectionManager.connectionChange.value.action {} else {
            XCTFail()
        }
    }

    func test_disconnect_ifItsConnected_itCancelsTheConnectionAndMovesToDisconnectedState() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        prepareConnectedSorc("1a", peripheral: peripheral, connectionManager: connectionManager, centralManager: centralManager)

        // When
        connectionManager.disconnect()

        // Then
        XCTAssertEqual(centralManager.cancelConnectionCalledWithPeripheral?.identifier, peripheral.identifier)
        if case .disconnected = connectionManager.connectionChange.value.state {} else {
            XCTFail()
        }
        if case .disconnect = connectionManager.connectionChange.value.action {} else {
            XCTFail()
        }
    }

    func test_sendData_ifItsConnected_itWritesTheDataToThePeripheralWithResponse() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        prepareConnectedSorc("1a", peripheral: peripheral, connectionManager: connectionManager, centralManager: centralManager)
        let data = Data(bytes: [42])

        // When
        connectionManager.sendData(data)

        // Then
        let arguments = peripheral.writeValueCalledWithArguments
        XCTAssertEqual(arguments?.data, data)
        XCTAssertEqual(arguments?.type, CBCharacteristicWriteType.withResponse)
    }

    func test_sendData_ifItsNotConnected_itDoesNotWriteTheDataToThePeripheral() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        let data = Data(bytes: [42])

        // When
        connectionManager.sendData(data)

        // Then
        XCTAssertNil(peripheral.writeValueCalledWithArguments)
    }

    func test_centralManagerDidUpdateState_sendsIsPoweredOnUpdate() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)

        var isPoweredOnUpdate: Bool?
        _ = connectionManager.isPoweredOn.subscribeNext { isPoweredOn in
            isPoweredOnUpdate = isPoweredOn
        }

        // When
        connectionManager.centralManagerDidUpdateState_(centralManager)

        // Then
        XCTAssertFalse(isPoweredOnUpdate!)
    }

    func test_centralManagerDidUpdateState_ifCentralManagerIsPoweredOn_itScansForPeripheralsAllowingDuplicates() {

        // Given
        let centralManager = CBCentralManagerMock()
        centralManager.state = .poweredOn
        let connectionManager = SorcConnectionManager(centralManager: centralManager)

        // When
        connectionManager.centralManagerDidUpdateState_(centralManager)

        // Then
        let arguments = centralManager.scanForPeripheralsCalledWithArguments
        XCTAssertNil(arguments.serviceUUIDs)
        XCTAssertTrue(arguments.options![CBCentralManagerScanOptionAllowDuplicatesKey] as! Int == 1)
    }

    func test_centralManagerDidUpdateState_ifCentralManagerIsNotPoweredOn_itResetsDiscoveredSorcs() {

        // Given
        let centralManager = CBCentralManagerMock()
        centralManager.state = .poweredOn
        let connectionManager = SorcConnectionManager(centralManager: centralManager)

        let peripheral = CBPeripheralMock()
        prepareDiscoveredSorc("1a", peripheral: peripheral, connectionManager: connectionManager, centralManager: centralManager)

        // When
        centralManager.state = .poweredOff
        connectionManager.centralManagerDidUpdateState_(centralManager)

        // Then
        XCTAssert(connectionManager.discoveryChange.value.state.isEmpty)
        if case .sorcsReset = connectionManager.discoveryChange.value.action {} else {
            XCTFail()
        }
    }

    func test_centralManagerDidDiscoverPeripheral_ifManufacturerDataKeyIsSet_addsSorcToDiscoveredSorcs() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)

        let sorcID = "1a"
        let peripheral = CBPeripheralMock()

        let advertisementData: [String: Any] = [
            CBAdvertisementDataManufacturerDataKey: sorcID.dataFromHexadecimalString()!,
        ]

        // When
        connectionManager.centralManager_(centralManager, didDiscover: peripheral, advertisementData: advertisementData, rssi: 0)

        // Then
        XCTAssert(connectionManager.discoveryChange.value.state.contains("1a"))
        if case let .sorcDiscovered(discoveredSorcID) = connectionManager.discoveryChange.value.action {
            XCTAssertEqual(discoveredSorcID, "1a")
        } else {
            XCTFail()
        }
    }

    func test_centralManagerDidDiscoverPeripheral_ifManufacturerDataKeyIsNotSet_doesNotUpdateDiscoveredSorcs() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)

        let peripheral = CBPeripheralMock()
        let advertisementData = [String: Any]()

        // When
        connectionManager.centralManager_(centralManager, didDiscover: peripheral, advertisementData: advertisementData, rssi: 0)

        // Then
        if case .initial = connectionManager.discoveryChange.value.action {} else {
            XCTFail()
        }
    }

    func test_centralManagerDidConnectPeripheral_ifItsConnectingAndPeripheralIsDiscovered_triesToDiscoverServicesOfPeripheral() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)

        let peripheral = CBPeripheralMock()

        prepareConnectingSorc("1a", peripheral: peripheral, connectionManager: connectionManager, centralManager: centralManager)

        // When
        connectionManager.centralManager_(centralManager, didConnect: peripheral)

        // Then
        XCTAssertEqual(peripheral.discoverServicesCalledWithUUIDs!, [CBUUID(string: serviceId)])
    }

    func test_centralManagerDidConnectPeripheral_ifItsNotConnecting_doesNotTryToDiscoverServices() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)

        let peripheral = CBPeripheralMock()

        // When
        connectionManager.centralManager_(centralManager, didConnect: peripheral)

        // Then
        XCTAssertNil(peripheral.discoverServicesCalledWithUUIDs)
    }

    func test_centralManagerDidFailToConnect_ifItsConnectingAndPeripheralIsDiscovered_connectionStateDisconnected() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)

        let peripheral = CBPeripheralMock()

        prepareConnectingSorc("1a", peripheral: peripheral, connectionManager: connectionManager, centralManager: centralManager)

        // When
        connectionManager.centralManager_(centralManager, didFailToConnect: peripheral, error: nil)

        // Then
        if case .disconnected = connectionManager.connectionChange.value.state {} else {
            XCTFail()
        }
        if case let .connectingFailed(sorcID) = connectionManager.connectionChange.value.action {
            XCTAssertEqual("1a", sorcID)
        } else {
            XCTFail()
        }
    }

    func test_centralManagerDidFailToConnect_ifItsNotConnecting_connectionStateNotUpdated() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)

        let peripheral = CBPeripheralMock()

        prepareConnectedSorc("1a", peripheral: peripheral, connectionManager: connectionManager, centralManager: centralManager)

        // When
        connectionManager.centralManager_(centralManager, didFailToConnect: peripheral, error: nil)

        // Then
        if case .connected = connectionManager.connectionChange.value.state {} else {
            XCTFail()
        }
    }

    func test_centralManagerDidDisconnectPeripheral_ifItsConnected_removesDiscoveredSorcAndConnectionStateDisconnected() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)

        let peripheral = CBPeripheralMock()

        prepareConnectedSorc("1a", peripheral: peripheral, connectionManager: connectionManager, centralManager: centralManager)

        // When
        connectionManager.centralManager_(centralManager, didDisconnectPeripheral: peripheral, error: nil)

        // Then
        if case let .sorcDisconnected(disconnectedSorcID) = connectionManager.discoveryChange.value.action {
            XCTAssertEqual(disconnectedSorcID, "1a")
        } else {
            XCTFail()
        }
        if case .disconnected = connectionManager.connectionChange.value.state {} else {
            XCTFail()
        }
        if case let .disconnected(disconnectedSorcID) = connectionManager.connectionChange.value.action {
            XCTAssertEqual(disconnectedSorcID, "1a")
        } else {
            XCTFail()
        }
    }

    func test_centralManagerDidDisconnectPeripheral_ifItsNotConnected_doesNothing() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)

        let peripheral = CBPeripheralMock()

        prepareConnectingSorc("1a", peripheral: peripheral, connectionManager: connectionManager, centralManager: centralManager)

        // When
        connectionManager.centralManager_(centralManager, didDisconnectPeripheral: peripheral, error: nil)

        // Then
        if case .sorcDisconnected = connectionManager.discoveryChange.value.action {
            XCTFail()
        }
        if case .connecting = connectionManager.connectionChange.value.state {} else {
            XCTFail()
        }
    }

    func test_peripheralDidDiscoverServices_ifItsConnectingAndPeripheralIsDiscoveredAndErrorIsNil_triesToDiscoverCharacteristicsForService() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        let service = CBServiceMock()
        peripheral.services_ = [service]

        prepareConnectingSorc("1a", peripheral: peripheral, connectionManager: connectionManager, centralManager: centralManager)

        // When
        connectionManager.peripheral_(peripheral, didDiscoverServices: nil)

        // Then
        if let arguments = peripheral.discoverCharacteristicsCalledWithArguments {
            XCTAssert(arguments.characteristicUUIDs!.contains(CBUUID(string: writeCharacteristicId)))
            XCTAssert(arguments.characteristicUUIDs!.contains(CBUUID(string: notifyCharacteristicId)))
        } else {
            XCTFail()
        }
    }

    func test_peripheralDidDiscoverServices_ifItsConnectingAndPeripheralIsDiscoveredAndErrorExists_connectingFailed() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        let service = CBServiceMock()
        peripheral.services_ = [service]

        prepareConnectingSorc("1a", peripheral: peripheral, connectionManager: connectionManager, centralManager: centralManager)

        // When
        connectionManager.peripheral_(peripheral, didDiscoverServices: NSError(domain: "", code: 0, userInfo: nil))

        // Then
        if case .disconnected = connectionManager.connectionChange.value.state {} else {
            XCTFail()
        }
        if case let .connectingFailed(disconnectedSorcID) = connectionManager.connectionChange.value.action {
            XCTAssertEqual(disconnectedSorcID, "1a")
        } else {
            XCTFail()
        }
    }

    func test_peripheralDidDiscoverCharacteristics_ifItsConnectingAndPeripheralIsDiscoveredAndErrorIsNil_connectedAndSetNotifyValue() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        let service = CBServiceMock()
        peripheral.services_ = [service]

        let writeCharacteristic = CBCharacteristicMock()
        writeCharacteristic.uuid = CBUUID(string: writeCharacteristicId)
        let notifyCharacteristic = CBCharacteristicMock()
        notifyCharacteristic.uuid = CBUUID(string: notifyCharacteristicId)
        service.characteristics_ = [writeCharacteristic, notifyCharacteristic]

        prepareConnectingSorc("1a", peripheral: peripheral, connectionManager: connectionManager, centralManager: centralManager)

        // When
        connectionManager.peripheral_(peripheral, didDiscoverCharacteristicsFor: service, error: nil)

        // Then
        if case let .connected(sorcID) = connectionManager.connectionChange.value.state {
            XCTAssertEqual(sorcID, "1a")
        } else {
            XCTFail()
        }
        if case let .connectionEstablished(sorcID) = connectionManager.connectionChange.value.action {
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

    func test_peripheralDidDiscoverCharacteristics_ifItsConnectingAndPeripheralIsDiscoveredAndErrorExists_connectingFailed() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        let service = CBServiceMock()
        peripheral.services_ = [service]

        prepareConnectingSorc("1a", peripheral: peripheral, connectionManager: connectionManager, centralManager: centralManager)

        // When
        connectionManager.peripheral_(peripheral, didDiscoverCharacteristicsFor: service, error: NSError(domain: "", code: 0, userInfo: nil))

        // Then
        if case .disconnected = connectionManager.connectionChange.value.state {} else {
            XCTFail()
        }
        if case let .connectingFailed(sorcID) = connectionManager.connectionChange.value.action {
            XCTAssertEqual(sorcID, "1a")
        } else {
            XCTFail()
        }
    }

    func test_peripheralDidUpdateValue_ifNotifyCharacteristicAndErrorIsNil_receivedDataSuccess() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)
        let notifyCharacteristic = CBCharacteristicMock()
        notifyCharacteristic.value = Data(base64Encoded: "data")
        notifyCharacteristic.uuid = CBUUID(string: notifyCharacteristicId)

        var receivedData: Data?
        _ = connectionManager.receivedData.subscribeNext { result in
            if case let .success(data) = result {
                receivedData = data
            }
        }

        // When
        connectionManager.peripheral_(CBPeripheralMock(), didUpdateValueFor: notifyCharacteristic, error: nil)

        // Then
        XCTAssertEqual(receivedData, Data(base64Encoded: "data"))
    }

    func test_peripheralDidUpdateValue_ifNotifyCharacteristicAndErrorExists_receivedDataError() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)
        let notifyCharacteristic = CBCharacteristicMock()
        notifyCharacteristic.value = Data(base64Encoded: "data")
        notifyCharacteristic.uuid = CBUUID(string: notifyCharacteristicId)

        var receivedDataError: Error?
        _ = connectionManager.receivedData.subscribeNext { result in
            if case let .error(error) = result {
                receivedDataError = error
            }
        }

        let error = NSError(domain: "", code: 0, userInfo: nil)

        // When
        connectionManager.peripheral_(CBPeripheralMock(), didUpdateValueFor: notifyCharacteristic, error: error)

        // Then
        XCTAssertEqual(receivedDataError! as NSError, error)
    }

    func test_peripheralDidWriteValue_ifWriteCharacteristicAndErrorIsNil_sentDataErrorIsNil() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)
        let writeCharacteristic = CBCharacteristicMock()
        writeCharacteristic.uuid = CBUUID(string: writeCharacteristicId)

        var sentDataError: Error?
        _ = connectionManager.sentData.subscribeNext { error in
            sentDataError = error
        }

        // When
        connectionManager.peripheral_(CBPeripheralMock(), didWriteValueFor: writeCharacteristic, error: nil)

        // Then
        XCTAssertNil(sentDataError)
    }

    func test_peripheralDidWriteValue_ifWriteCharacteristicAndErrorExists_sentDataErrorExists() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)
        let writeCharacteristic = CBCharacteristicMock()
        writeCharacteristic.uuid = CBUUID(string: writeCharacteristicId)

        var sentDataError: Error?
        _ = connectionManager.sentData.subscribeNext { error in
            sentDataError = error
        }

        let error = NSError(domain: "", code: 0, userInfo: nil)

        // When
        connectionManager.peripheral_(CBPeripheralMock(), didWriteValueFor: writeCharacteristic, error: error)

        // Then
        XCTAssertEqual(sentDataError! as NSError, error)
    }

    func test_filterTimerFired_ifDiscoveredSorcIsOutdatedAndNotConnected_removesIt() {

        // Given
        let centralManager = CBCentralManagerMock()
        let systemClock = SystemClockMock(currentNow: Date(timeIntervalSince1970: 0))

        var fireTimer: (() -> Void)!
        let createTimer: SorcConnectionManager.CreateTimer = { block in
            fireTimer = block
            return Timer()
        }

        let connectionManager = SorcConnectionManager(centralManager: centralManager, systemClock: systemClock, createTimer: createTimer)

        prepareDiscoveredSorc("1a", peripheral: CBPeripheralMock(), connectionManager: connectionManager, centralManager: centralManager)

        // Moving system time forward 6 seconds, sorcOutdatedDurationSeconds == 5
        systemClock.currentNow = Date(timeIntervalSince1970: 6)

        // When
        fireTimer()

        // Then
        XCTAssert(!connectionManager.discoveryChange.value.state.contains("1a"))
    }

    func test_filterTimerFired_ifDiscoveredSorcIsOutdatedAndConnected_keepsIt() {

        // Given
        let centralManager = CBCentralManagerMock()
        let systemClock = SystemClockMock(currentNow: Date(timeIntervalSince1970: 0))

        var fireTimer: (() -> Void)!
        let createTimer: SorcConnectionManager.CreateTimer = { block in
            fireTimer = block
            return Timer()
        }

        let connectionManager = SorcConnectionManager(centralManager: centralManager, systemClock: systemClock, createTimer: createTimer)

        prepareConnectedSorc("1a", peripheral: CBPeripheralMock(), connectionManager: connectionManager, centralManager: centralManager)

        // Moving system time forward 6 seconds, sorcOutdatedDurationSeconds == 5
        systemClock.currentNow = Date(timeIntervalSince1970: 6)

        // When
        fireTimer()

        // Then
        XCTAssert(connectionManager.discoveryChange.value.state.contains("1a"))
    }

    private func prepareDiscoveredSorc(_ sorcID: SorcID, peripheral: CBPeripheralType, connectionManager: SorcConnectionManager, centralManager: CBCentralManagerMock) {
        let advertisementData: [String: Any] = [
            CBAdvertisementDataManufacturerDataKey: sorcID.dataFromHexadecimalString()!,
        ]
        connectionManager.centralManager_(centralManager, didDiscover: peripheral, advertisementData: advertisementData, rssi: 0)
    }

    private func prepareConnectingSorc(_ sorcID: SorcID, peripheral: CBPeripheralType, connectionManager: SorcConnectionManager, centralManager: CBCentralManagerMock) {
        prepareDiscoveredSorc(sorcID, peripheral: peripheral, connectionManager: connectionManager, centralManager: centralManager)
        connectionManager.connectToSorc(sorcID)

        centralManager.connectCalledWithPeripheral = nil
    }

    private func prepareConnectedSorc(_ sorcID: SorcID, peripheral: CBPeripheralMock, connectionManager: SorcConnectionManager, centralManager: CBCentralManagerMock) {
        prepareDiscoveredSorc(sorcID, peripheral: peripheral, connectionManager: connectionManager, centralManager: centralManager)
        connectionManager.connectToSorc(sorcID)
        connectionManager.centralManager_(centralManager, didConnect: peripheral)

        let service = CBServiceMock()
        peripheral.services_ = [service]
        connectionManager.peripheral_(peripheral, didDiscoverServices: nil)

        let notifyCharacteristic = CBCharacteristicMock()
        notifyCharacteristic.uuid = CBUUID(string: notifyCharacteristicId)
        let writeCharacteristic = CBCharacteristicMock()
        writeCharacteristic.uuid = CBUUID(string: writeCharacteristicId)
        service.characteristics_ = [notifyCharacteristic, writeCharacteristic]

        connectionManager.peripheral_(peripheral, didDiscoverCharacteristicsFor: service, error: nil)

        centralManager.connectCalledWithPeripheral = nil
    }
}