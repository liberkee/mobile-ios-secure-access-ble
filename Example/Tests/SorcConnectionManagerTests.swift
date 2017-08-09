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

    var writeValueCalledWithArguments: (data: Data, characteristic: CBCharacteristicType,
                                        type: CBCharacteristicWriteType)?
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

    let sorcID1 = "82f6ed49-b70d-4c9e-afa1-4b0377d0de5f"
    let sorcID2 = "a8c5e6b9-9df1-4194-a214-88636a048fcb"

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
        connectionManager.connectToSorc(sorcID1)

        // Then
        if case .connecting = connectionManager.connectionChange.state {
            XCTFail()
        }
        XCTAssertNil(centralManager.connectCalledWithPeripheral)
    }

    func test_connectToSorc_ifDisconnected_itMovesToConnectingStateAndItTriesToConnectToPeripheral() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        prepareDiscoveredSorc(sorcID1, peripheral: peripheral, connectionManager: connectionManager,
                              centralManager: centralManager)

        var receivedConnectionChange: SorcConnectionManager.ConnectionChange!
        _ = connectionManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        connectionManager.connectToSorc(sorcID1)

        // Then
        let expected = SorcConnectionManager.ConnectionChange(state: .connecting(sorcID: sorcID1),
                                                              action: .connect(sorcID: sorcID1))
        XCTAssertEqual(receivedConnectionChange, expected)
        XCTAssertEqual(centralManager.connectCalledWithPeripheral?.identifier, peripheral.identifier)
    }

    func test_connectToSorc_ifConnectingToSameSorc_itStaysInConnectingStateAndItTriesToConnectToPeripheralAgain() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        prepareConnectingSorc(sorcID1, peripheral: peripheral, connectionManager: connectionManager,
                              centralManager: centralManager)

        var receivedConnectionChange: SorcConnectionManager.ConnectionChange!
        _ = connectionManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        connectionManager.connectToSorc(sorcID1)

        // Then
        let expected = SorcConnectionManager.ConnectionChange(state: .connecting(sorcID: sorcID1),
                                                              action: .initial)
        XCTAssertEqual(receivedConnectionChange, expected)
        XCTAssertEqual(centralManager.connectCalledWithPeripheral?.identifier, peripheral.identifier)
    }

    func test_connectToSorc_ifConnectingToOtherSorc_itMovesToConnectingToOtherSorcStateAndItTriesToConnectToOtherPeripheral() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)
        let peripheral1 = CBPeripheralMock()
        prepareConnectingSorc(sorcID1, peripheral: peripheral1, connectionManager: connectionManager, centralManager: centralManager)

        let peripheral2 = CBPeripheralMock()
        prepareDiscoveredSorc(sorcID2, peripheral: peripheral2, connectionManager: connectionManager, centralManager: centralManager)

        var receivedConnectionChange: SorcConnectionManager.ConnectionChange!
        _ = connectionManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        connectionManager.connectToSorc(sorcID2)

        // Then
        let expected = SorcConnectionManager.ConnectionChange(state: .connecting(sorcID: sorcID2),
                                                              action: .connect(sorcID: sorcID2))
        XCTAssertEqual(receivedConnectionChange, expected)
        XCTAssertEqual(centralManager.connectCalledWithPeripheral?.identifier, peripheral2.identifier)
    }

    func test_connectToSorc_ifAlreadyConnectedToSameSorc_itDoesNotConnectAgain() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        prepareConnectedSorc(sorcID1, peripheral: peripheral, connectionManager: connectionManager,
                             centralManager: centralManager)

        var receivedConnectionChange: SorcConnectionManager.ConnectionChange!
        _ = connectionManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        connectionManager.connectToSorc(sorcID1)

        // Then
        let expected = SorcConnectionManager.ConnectionChange(state: .connected(sorcID: sorcID1),
                                                              action: .initial)
        XCTAssertEqual(receivedConnectionChange, expected)
        XCTAssertNil(centralManager.connectCalledWithPeripheral)
    }

    func test_connectToSorc_ifConnectedToAnotherSorc_itDisconnectsFromTheCurrentPeripheralAndTriesToConnectToTheNewPeripheral() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)
        let peripheral1 = CBPeripheralMock()
        prepareConnectedSorc(sorcID1, peripheral: peripheral1, connectionManager: connectionManager,
                             centralManager: centralManager)

        let peripheral2 = CBPeripheralMock()
        prepareDiscoveredSorc(sorcID2, peripheral: peripheral2, connectionManager: connectionManager,
                              centralManager: centralManager)

        var receivedConnectionChange: SorcConnectionManager.ConnectionChange!
        _ = connectionManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        connectionManager.connectToSorc(sorcID2)

        // Then
        XCTAssertEqual(centralManager.cancelConnectionCalledWithPeripheral?.identifier, peripheral1.identifier)

        let expected = SorcConnectionManager.ConnectionChange(state: .connecting(sorcID: sorcID2),
                                                              action: .connect(sorcID: sorcID2))
        XCTAssertEqual(receivedConnectionChange, expected)

        XCTAssertEqual(centralManager.connectCalledWithPeripheral?.identifier, peripheral2.identifier)
    }

    func test_disconnect_ifItsConnecting_itCancelsTheConnectionAndMovesToDisconnectedState() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        prepareConnectingSorc(sorcID1, peripheral: peripheral, connectionManager: connectionManager,
                              centralManager: centralManager)

        var receivedDiscoveryChange: DiscoveryChange!
        _ = connectionManager.discoveryChange.subscribeNext { change in
            receivedDiscoveryChange = change
        }

        var receivedConnectionChange: SorcConnectionManager.ConnectionChange!
        _ = connectionManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        connectionManager.disconnect()

        // Then
        XCTAssertEqual(centralManager.cancelConnectionCalledWithPeripheral?.identifier, peripheral.identifier)

        XCTAssert(!receivedDiscoveryChange.state.contains(sorcID1))
        XCTAssertEqual(receivedDiscoveryChange.action, .disconnect(sorcID: sorcID1))

        let expected = SorcConnectionManager.ConnectionChange(state: .disconnected,
                                                              action: .disconnect(sorcID: sorcID1))
        XCTAssertEqual(receivedConnectionChange, expected)
    }

    func test_disconnect_ifItsConnected_itCancelsTheConnectionAndMovesToDisconnectedState() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        prepareConnectedSorc(sorcID1, peripheral: peripheral, connectionManager: connectionManager,
                             centralManager: centralManager)

        var receivedDiscoveryChange: DiscoveryChange!
        _ = connectionManager.discoveryChange.subscribeNext { change in
            receivedDiscoveryChange = change
        }

        var receivedConnectionChange: SorcConnectionManager.ConnectionChange!
        _ = connectionManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        connectionManager.disconnect()

        // Then
        XCTAssertEqual(centralManager.cancelConnectionCalledWithPeripheral?.identifier, peripheral.identifier)

        XCTAssert(!receivedDiscoveryChange.state.contains(sorcID1))
        XCTAssertEqual(receivedDiscoveryChange.action, .disconnect(sorcID: sorcID1))

        let expected = SorcConnectionManager.ConnectionChange(state: .disconnected,
                                                              action: .disconnect(sorcID: sorcID1))
        XCTAssertEqual(receivedConnectionChange, expected)
    }

    func test_sendData_ifItsConnected_itWritesTheDataToThePeripheralWithResponse() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        prepareConnectedSorc(sorcID1, peripheral: peripheral, connectionManager: connectionManager,
                             centralManager: centralManager)
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
        prepareDiscoveredSorc(sorcID1, peripheral: peripheral, connectionManager: connectionManager,
                              centralManager: centralManager)

        var receivedDiscoveryChange: DiscoveryChange!
        _ = connectionManager.discoveryChange.subscribeNext { change in
            receivedDiscoveryChange = change
        }

        // When
        centralManager.state = .poweredOff
        connectionManager.centralManagerDidUpdateState_(centralManager)

        // Then
        XCTAssert(receivedDiscoveryChange.state.isEmpty)
        XCTAssertEqual(receivedDiscoveryChange.action, .reset)
    }

    func test_centralManagerDidDiscoverPeripheral_ifManufacturerDataKeyIsSet_addsSorcToDiscoveredSorcs() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)

        let peripheral = CBPeripheralMock()

        let strippedSorcID = sorcID1.replacingOccurrences(of: "-", with: "").dataFromHexadecimalString()!
        let advertisementData: [String: Any] = [
            CBAdvertisementDataManufacturerDataKey: strippedSorcID,
        ]

        var receivedDiscoveryChange: DiscoveryChange!
        _ = connectionManager.discoveryChange.subscribeNext { change in
            receivedDiscoveryChange = change
        }

        // When
        connectionManager.centralManager_(centralManager, didDiscover: peripheral, advertisementData: advertisementData,
                                          rssi: 0)

        // Then
        XCTAssert(receivedDiscoveryChange.state.contains(sorcID1))
        XCTAssertEqual(receivedDiscoveryChange.action, .discovered(sorcID: sorcID1))
    }

    func test_centralManagerDidDiscoverPeripheral_ifManufacturerDataKeyIsNotSet_doesNotUpdateDiscoveredSorcs() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)

        let peripheral = CBPeripheralMock()
        let advertisementData = [String: Any]()

        var receivedDiscoveryChange: DiscoveryChange!
        _ = connectionManager.discoveryChange.subscribeNext { change in
            receivedDiscoveryChange = change
        }

        // When
        connectionManager.centralManager_(centralManager, didDiscover: peripheral, advertisementData: advertisementData,
                                          rssi: 0)

        // Then
        XCTAssertEqual(receivedDiscoveryChange.action, .initial)
    }

    func test_centralManagerDidConnectPeripheral_ifItsConnectingAndPeripheralIsDiscovered_triesToDiscoverServicesOfPeripheral() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)

        let peripheral = CBPeripheralMock()

        prepareConnectingSorc(sorcID1, peripheral: peripheral, connectionManager: connectionManager,
                              centralManager: centralManager)

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

        prepareConnectingSorc(sorcID1, peripheral: peripheral, connectionManager: connectionManager,
                              centralManager: centralManager)

        var receivedConnectionChange: SorcConnectionManager.ConnectionChange!
        _ = connectionManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        connectionManager.centralManager_(centralManager, didFailToConnect: peripheral, error: nil)

        // Then
        let expected = SorcConnectionManager.ConnectionChange(state: .disconnected, action: .connectingFailed(sorcID: sorcID1))
        XCTAssertEqual(receivedConnectionChange, expected)
    }

    func test_centralManagerDidFailToConnect_ifItsNotConnecting_connectionStateNotUpdated() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)

        let peripheral = CBPeripheralMock()

        prepareConnectedSorc(sorcID1, peripheral: peripheral, connectionManager: connectionManager,
                             centralManager: centralManager)

        // When
        connectionManager.centralManager_(centralManager, didFailToConnect: peripheral, error: nil)

        // Then
        if case .connected = connectionManager.connectionChange.state {} else {
            XCTFail()
        }
    }

    func test_centralManagerDidDisconnectPeripheral_ifItsConnected_removesDiscoveredSorcAndConnectionStateDisconnected() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)

        let peripheral = CBPeripheralMock()

        prepareConnectedSorc(sorcID1, peripheral: peripheral, connectionManager: connectionManager,
                             centralManager: centralManager)

        var receivedDiscoveryChange: DiscoveryChange!
        _ = connectionManager.discoveryChange.subscribeNext { change in
            receivedDiscoveryChange = change
        }

        var receivedConnectionChange: SorcConnectionManager.ConnectionChange!
        _ = connectionManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        connectionManager.centralManager_(centralManager, didDisconnectPeripheral: peripheral, error: nil)

        // Then
        XCTAssert(!receivedDiscoveryChange.state.contains(sorcID1))
        XCTAssertEqual(receivedDiscoveryChange.action, .disconnected(sorcID: sorcID1))

        let expected = SorcConnectionManager.ConnectionChange(state: .disconnected, action: .disconnected(sorcID: sorcID1))
        XCTAssertEqual(receivedConnectionChange, expected)
    }

    func test_centralManagerDidDisconnectPeripheral_ifItsNotConnected_doesNothing() {

        // Given
        let centralManager = CBCentralManagerMock()
        let connectionManager = SorcConnectionManager(centralManager: centralManager)

        let peripheral = CBPeripheralMock()

        prepareConnectingSorc(sorcID1, peripheral: peripheral, connectionManager: connectionManager,
                              centralManager: centralManager)

        var receivedDiscoveryChange: DiscoveryChange!
        _ = connectionManager.discoveryChange.subscribeNext { change in
            receivedDiscoveryChange = change
        }

        // When
        connectionManager.centralManager_(centralManager, didDisconnectPeripheral: peripheral, error: nil)

        // Then
        XCTAssert(receivedDiscoveryChange.state.contains(sorcID1))
        XCTAssertEqual(receivedDiscoveryChange.action, .initial)

        if case .connecting = connectionManager.connectionChange.state {} else {
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

        prepareConnectingSorc(sorcID1, peripheral: peripheral, connectionManager: connectionManager,
                              centralManager: centralManager)

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

        prepareConnectingSorc(sorcID1, peripheral: peripheral, connectionManager: connectionManager,
                              centralManager: centralManager)

        var receivedConnectionChange: SorcConnectionManager.ConnectionChange!
        _ = connectionManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        connectionManager.peripheral_(peripheral, didDiscoverServices: NSError(domain: "", code: 0, userInfo: nil))

        // Then
        let expected = SorcConnectionManager.ConnectionChange(state: .disconnected,
                                                              action: .connectingFailed(sorcID: sorcID1))
        XCTAssertEqual(receivedConnectionChange, expected)
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

        prepareConnectingSorc(sorcID1, peripheral: peripheral, connectionManager: connectionManager,
                              centralManager: centralManager)

        var receivedConnectionChange: SorcConnectionManager.ConnectionChange!
        _ = connectionManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        connectionManager.peripheral_(peripheral, didDiscoverCharacteristicsFor: service, error: nil)

        // Then
        let expected = SorcConnectionManager.ConnectionChange(state: .connected(sorcID: sorcID1),
                                                              action: .connectionEstablished(sorcID: sorcID1))
        XCTAssertEqual(receivedConnectionChange, expected)

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

        prepareConnectingSorc(sorcID1, peripheral: peripheral, connectionManager: connectionManager,
                              centralManager: centralManager)

        var receivedConnectionChange: SorcConnectionManager.ConnectionChange!
        _ = connectionManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        connectionManager.peripheral_(peripheral, didDiscoverCharacteristicsFor: service,
                                      error: NSError(domain: "", code: 0, userInfo: nil))

        // Then
        let expected = SorcConnectionManager.ConnectionChange(state: .disconnected,
                                                              action: .connectingFailed(sorcID: sorcID1))
        XCTAssertEqual(receivedConnectionChange, expected)
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

        let connectionManager = SorcConnectionManager(centralManager: centralManager, systemClock: systemClock,
                                                      createTimer: createTimer)

        prepareDiscoveredSorc(sorcID1, peripheral: CBPeripheralMock(), connectionManager: connectionManager, centralManager: centralManager)

        // Moving system time forward 6 seconds, sorcOutdatedDurationSeconds == 5
        systemClock.currentNow = Date(timeIntervalSince1970: 6)

        // When
        fireTimer()

        // Then
        XCTAssert(!connectionManager.discoveryChange.state.contains(sorcID1))
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

        let connectionManager = SorcConnectionManager(centralManager: centralManager, systemClock: systemClock,
                                                      createTimer: createTimer)

        prepareConnectedSorc(sorcID1, peripheral: CBPeripheralMock(), connectionManager: connectionManager, centralManager: centralManager)

        // Moving system time forward 6 seconds, sorcOutdatedDurationSeconds == 5
        systemClock.currentNow = Date(timeIntervalSince1970: 6)

        // When
        fireTimer()

        // Then
        XCTAssert(connectionManager.discoveryChange.state.contains(sorcID1))
    }

    private func prepareDiscoveredSorc(_ sorcID: SorcID, peripheral: CBPeripheralType,
                                       connectionManager: SorcConnectionManager, centralManager: CBCentralManagerMock) {

        let strippedSorcID = sorcID.replacingOccurrences(of: "-", with: "").dataFromHexadecimalString()!
        let advertisementData: [String: Any] = [
            CBAdvertisementDataManufacturerDataKey: strippedSorcID,
        ]
        connectionManager.centralManager_(centralManager, didDiscover: peripheral, advertisementData: advertisementData,
                                          rssi: 0)
    }

    private func prepareConnectingSorc(_ sorcID: SorcID, peripheral: CBPeripheralType,
                                       connectionManager: SorcConnectionManager, centralManager: CBCentralManagerMock) {

        prepareDiscoveredSorc(sorcID, peripheral: peripheral, connectionManager: connectionManager,
                              centralManager: centralManager)
        connectionManager.connectToSorc(sorcID)

        centralManager.connectCalledWithPeripheral = nil
    }

    private func prepareConnectedSorc(_ sorcID: SorcID, peripheral: CBPeripheralMock,
                                      connectionManager: SorcConnectionManager, centralManager: CBCentralManagerMock) {

        prepareDiscoveredSorc(sorcID, peripheral: peripheral, connectionManager: connectionManager,
                              centralManager: centralManager)
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
