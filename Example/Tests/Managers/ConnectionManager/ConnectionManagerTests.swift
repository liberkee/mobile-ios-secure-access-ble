//
//  ConnectionManagerTests.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import XCTest
@testable import SecureAccessBLE
import CoreBluetooth
import CommonUtils

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

    var scanForPeripheralsCalledWithArguments: (serviceUUIDs: [CBUUID]?, options: [String: Any]?)?
    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String: Any]?) {
        scanForPeripheralsCalledWithArguments = (serviceUUIDs: serviceUUIDs, options: options)
    }

    var stopScanCalled = false
    func stopScan() {
        stopScanCalled = true
    }

    var connectCalledWithPeripheral: CBPeripheralType?
    func connect(_ peripheral: CBPeripheralType, options _: [String: Any]?) {
        connectCalledWithPeripheral = peripheral
    }

    var cancelConnectionCalledWithPeripheral: CBPeripheralType?
    func cancelPeripheralConnection(_ peripheral: CBPeripheralType) {
        cancelConnectionCalledWithPeripheral = peripheral
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

class AppActivityStatusProviderMock: AppActivityStatusProviderType {
    var appDidBecomeActive: EventSignal<()> {
        return appDidBecomeActiveSubject.asSignal()
    }

    let appDidBecomeActiveSubject = PublishSubject<()>()
}

extension ConnectionManager {

    convenience init(centralManager: CBCentralManagerType, createTimer: CreateTimer? = nil) {

        let createTimer: CreateTimer = createTimer ?? { block in
            Timer(timeInterval: 1000, repeats: false, block: { _ in block() })
        }
        let appActivityStatusProvider = AppActivityStatusProvider(notificationCenter: NotificationCenter.default)
        self.init(
            centralManager: centralManager,
            systemClock: SystemClock(),
            createTimer: createTimer,
            appActivityStatusProvider: appActivityStatusProvider
        )
    }

    convenience init(centralManager: CBCentralManagerType, systemClock: SystemClockType) {

        let createTimer: CreateTimer = { block in
            Timer(timeInterval: 1000, repeats: false, block: { _ in block() })
        }
        let appActivityStatusProvider = AppActivityStatusProvider(notificationCenter: NotificationCenter.default)
        self.init(
            centralManager: centralManager,
            systemClock: systemClock,
            createTimer: createTimer,
            appActivityStatusProvider: appActivityStatusProvider
        )
    }

    convenience init(centralManager: CBCentralManagerType, appActivityStatusProvider: AppActivityStatusProviderType) {

        let createTimer: CreateTimer = { block in
            Timer(timeInterval: 1000, repeats: false, block: { _ in block() })
        }
        self.init(
            centralManager: centralManager,
            systemClock: SystemClock(),
            createTimer: createTimer,
            appActivityStatusProvider: appActivityStatusProvider
        )
    }
}

class ConnectionManagerTests: XCTestCase {

    let notifyCharacteristicID = "d1d7a6b6-457e-458a-b237-a9df99b3d98b"
    let writeCharacteristicID = "c8e58f23-9417-41c6-97a8-70f6b2c8cab9"
    let serviceID = "d1cf0603-b501-4569-a4b9-e47ad3f628a5"

    let sorcID1 = "82f6ed49-b70d-4c9e-afa1-4b0377d0de5f"
    let sorcID2 = "a8c5e6b9-9df1-4194-a214-88636a048fcb"

    let centralManager = CBCentralManagerMock()

    func test_isBluetoothEnabled_ifCentralManagerIsPoweredOn_returnsTrue() {

        // Given
        centralManager.state = .poweredOn
        let connectionManager = ConnectionManager(centralManager: centralManager)

        // Then
        XCTAssertTrue(connectionManager.isBluetoothEnabled.value)
    }

    func test_isBluetoothEnabled_ifCentralManagerIsNotPoweredOn_returnsFalse() {

        // Given
        centralManager.state = .poweredOff
        let connectionManager = ConnectionManager(centralManager: centralManager)

        // Then
        XCTAssertFalse(connectionManager.isBluetoothEnabled.value)
    }

    func test_startDiscovery_ifCentralManagerIsPoweredOn_scanForPeripheralsIsCalledAndDiscoveryIsEnabled() {

        // Given
        centralManager.state = .poweredOn
        let connectionManager = ConnectionManager(centralManager: centralManager)

        // When
        connectionManager.startDiscovery()

        // Then
        let arguments = centralManager.scanForPeripheralsCalledWithArguments!
        XCTAssertNil(arguments.serviceUUIDs)
        XCTAssertTrue(arguments.options![CBCentralManagerScanOptionAllowDuplicatesKey] as! Int == 1)
        XCTAssertTrue(connectionManager.discoveryChange.state.discoveryIsEnabled)
    }

    func test_startDiscovery_ifCentralManagerIsNotPoweredOn_nothingIsCalled() {

        // Given
        centralManager.state = .poweredOff
        let connectionManager = ConnectionManager(centralManager: centralManager)

        // When
        connectionManager.startDiscovery()

        // Then
        XCTAssertNil(centralManager.scanForPeripheralsCalledWithArguments)
        XCTAssertFalse(connectionManager.discoveryChange.state.discoveryIsEnabled)
    }

    func test_stopDiscovery_stopsScanOnCentralAndDiscoveryIsNotEnabled() {

        // Given discovery is enabled
        let connectionManager = ConnectionManager(centralManager: centralManager)
        startDiscovery(connectionManager: connectionManager, centralManager: centralManager)

        // When
        connectionManager.stopDiscovery()

        // Then
        XCTAssertTrue(centralManager.stopScanCalled)
        XCTAssertFalse(connectionManager.discoveryChange.state.discoveryIsEnabled)
    }

    func test_connectToSorc_ifSorcIsNotDiscovered_itDoesNotMoveToConnectingStateAndItDoesNotTryToConnectToAPeripheral() {

        // Given
        let connectionManager = ConnectionManager(centralManager: centralManager)

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
        let connectionManager = ConnectionManager(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        prepareDiscoveredSorc(sorcID1, peripheral: peripheral, connectionManager: connectionManager,
                              centralManager: centralManager)

        var receivedConnectionChange: PhysicalConnectionChange!
        _ = connectionManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        connectionManager.connectToSorc(sorcID1)

        // Then
        let expected = PhysicalConnectionChange(state: .connecting(sorcID: sorcID1),
                                                action: .connect(sorcID: sorcID1))
        XCTAssertEqual(receivedConnectionChange, expected)
        XCTAssertEqual(centralManager.connectCalledWithPeripheral?.identifier, peripheral.identifier)
    }

    func test_connectToSorc_ifConnectingToSameSorc_itStaysInConnectingStateAndItTriesToConnectToPeripheralAgain() {

        // Given
        let connectionManager = ConnectionManager(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        prepareConnectingSorc(sorcID1, peripheral: peripheral, connectionManager: connectionManager,
                              centralManager: centralManager)

        var receivedConnectionChange: PhysicalConnectionChange!
        _ = connectionManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        connectionManager.connectToSorc(sorcID1)

        // Then
        let expected = PhysicalConnectionChange(state: .connecting(sorcID: sorcID1),
                                                action: .initial)
        XCTAssertEqual(receivedConnectionChange, expected)
        XCTAssertEqual(centralManager.connectCalledWithPeripheral?.identifier, peripheral.identifier)
    }

    func test_connectToSorc_ifConnectingToOtherSorc_itMovesToConnectingToOtherSorcStateAndItTriesToConnectToOtherPeripheral() {

        // Given
        let connectionManager = ConnectionManager(centralManager: centralManager)
        let peripheral1 = CBPeripheralMock()
        prepareConnectingSorc(sorcID1, peripheral: peripheral1, connectionManager: connectionManager, centralManager: centralManager)

        let peripheral2 = CBPeripheralMock()
        prepareDiscoveredSorc(sorcID2, peripheral: peripheral2, connectionManager: connectionManager, centralManager: centralManager)

        var receivedConnectionChange: PhysicalConnectionChange!
        _ = connectionManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        connectionManager.connectToSorc(sorcID2)

        // Then
        let expected = PhysicalConnectionChange(state: .connecting(sorcID: sorcID2),
                                                action: .connect(sorcID: sorcID2))
        XCTAssertEqual(receivedConnectionChange, expected)
        XCTAssertEqual(centralManager.connectCalledWithPeripheral?.identifier, peripheral2.identifier)
    }

    func test_connectToSorc_ifAlreadyConnectedToSameSorc_itDoesNotConnectAgain() {

        // Given
        let connectionManager = ConnectionManager(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        prepareConnectedSorc(sorcID1, peripheral: peripheral, connectionManager: connectionManager,
                             centralManager: centralManager)

        var receivedConnectionChange: PhysicalConnectionChange!
        _ = connectionManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        connectionManager.connectToSorc(sorcID1)

        // Then
        let expected = PhysicalConnectionChange(state: .connected(sorcID: sorcID1),
                                                action: .initial)
        XCTAssertEqual(receivedConnectionChange, expected)
        XCTAssertNil(centralManager.connectCalledWithPeripheral)
    }

    func test_connectToSorc_ifConnectedToAnotherSorc_itDisconnectsFromTheCurrentPeripheralAndTriesToConnectToTheNewPeripheral() {

        // Given
        let connectionManager = ConnectionManager(centralManager: centralManager)
        let peripheral1 = CBPeripheralMock()
        prepareConnectedSorc(sorcID1, peripheral: peripheral1, connectionManager: connectionManager,
                             centralManager: centralManager)

        let peripheral2 = CBPeripheralMock()
        prepareDiscoveredSorc(sorcID2, peripheral: peripheral2, connectionManager: connectionManager,
                              centralManager: centralManager)

        var receivedConnectionChange: PhysicalConnectionChange!
        _ = connectionManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        connectionManager.connectToSorc(sorcID2)

        // Then
        XCTAssertEqual(centralManager.cancelConnectionCalledWithPeripheral?.identifier, peripheral1.identifier)

        let expected = PhysicalConnectionChange(state: .connecting(sorcID: sorcID2),
                                                action: .connect(sorcID: sorcID2))
        XCTAssertEqual(receivedConnectionChange, expected)

        XCTAssertEqual(centralManager.connectCalledWithPeripheral?.identifier, peripheral2.identifier)
    }

    func test_disconnect_ifItsConnecting_itCancelsTheConnectionAndMovesToDisconnectedState() {

        // Given
        let connectionManager = ConnectionManager(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        prepareConnectingSorc(sorcID1, peripheral: peripheral, connectionManager: connectionManager,
                              centralManager: centralManager)

        var receivedDiscoveryChange: DiscoveryChange!
        _ = connectionManager.discoveryChange.subscribeNext { change in
            receivedDiscoveryChange = change
        }

        var receivedConnectionChange: PhysicalConnectionChange!
        _ = connectionManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        connectionManager.disconnect()

        // Then
        XCTAssertEqual(centralManager.cancelConnectionCalledWithPeripheral?.identifier, peripheral.identifier)

        XCTAssert(!receivedDiscoveryChange.state.discoveredSorcs.contains(sorcID1))
        XCTAssertEqual(receivedDiscoveryChange.action, .disconnect(sorcID: sorcID1))

        let expected = PhysicalConnectionChange(state: .disconnected,
                                                action: .disconnect(sorcID: sorcID1))
        XCTAssertEqual(receivedConnectionChange, expected)
    }

    func test_disconnect_ifItsConnected_itCancelsTheConnectionAndMovesToDisconnectedState() {

        // Given
        let connectionManager = ConnectionManager(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        prepareConnectedSorc(sorcID1, peripheral: peripheral, connectionManager: connectionManager,
                             centralManager: centralManager)

        var receivedDiscoveryChange: DiscoveryChange!
        _ = connectionManager.discoveryChange.subscribeNext { change in
            receivedDiscoveryChange = change
        }

        var receivedConnectionChange: PhysicalConnectionChange!
        _ = connectionManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        connectionManager.disconnect()

        // Then
        XCTAssertEqual(centralManager.cancelConnectionCalledWithPeripheral?.identifier, peripheral.identifier)

        XCTAssert(!receivedDiscoveryChange.state.discoveredSorcs.contains(sorcID1))
        XCTAssertEqual(receivedDiscoveryChange.action, .disconnect(sorcID: sorcID1))

        let expected = PhysicalConnectionChange(state: .disconnected,
                                                action: .disconnect(sorcID: sorcID1))
        XCTAssertEqual(receivedConnectionChange, expected)
    }

    func test_sendData_ifItsConnected_itWritesTheDataToThePeripheralWithResponse() {

        // Given
        let connectionManager = ConnectionManager(centralManager: centralManager)
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
        let connectionManager = ConnectionManager(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        let data = Data(bytes: [42])

        // When
        connectionManager.sendData(data)

        // Then
        XCTAssertNil(peripheral.writeValueCalledWithArguments)
    }

    func test_centralManagerDidUpdateState_sendsIsBluetoothEnabledUpdate() {

        // Given
        let connectionManager = ConnectionManager(centralManager: centralManager)

        var isBluetoothEnabledUpdate: Bool?
        _ = connectionManager.isBluetoothEnabled.subscribeNext { isBluetoothEnabled in
            isBluetoothEnabledUpdate = isBluetoothEnabled
        }

        // When
        connectionManager.centralManagerDidUpdateState_(centralManager)

        // Then
        XCTAssertFalse(isBluetoothEnabledUpdate!)
    }

    func test_centralManagerDidUpdateState_ifCentralManagerIsPoweredOnAndDiscoveryIsEnabled_itScansForPeripheralsAllowingDuplicates() {

        // Given
        let connectionManager = ConnectionManager(centralManager: centralManager)
        startDiscovery(connectionManager: connectionManager, centralManager: centralManager)

        // When
        connectionManager.centralManagerDidUpdateState_(centralManager)

        // Then
        let arguments = centralManager.scanForPeripheralsCalledWithArguments!
        XCTAssertNil(arguments.serviceUUIDs)
        XCTAssertTrue(arguments.options![CBCentralManagerScanOptionAllowDuplicatesKey] as! Int == 1)
    }

    func test_centralManagerDidUpdateState_ifCentralManagerIsNotPoweredOn_itResetsDiscoveredSorcs() {

        // Given
        centralManager.state = .poweredOn
        let connectionManager = ConnectionManager(centralManager: centralManager)

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
        XCTAssert(receivedDiscoveryChange.state.discoveredSorcs.isEmpty)
        XCTAssertEqual(receivedDiscoveryChange.action, .reset)
    }

    func test_centralManagerDidDiscoverPeripheral_ifManufacturerDataKeyIsSet_addsSorcToDiscoveredSorcs() {

        // Given
        let now = Date(timeIntervalSince1970: 0)
        let systemClock = SystemClockMock(currentNow: now)
        let connectionManager = ConnectionManager(centralManager: centralManager, systemClock: systemClock)
        startDiscovery(connectionManager: connectionManager, centralManager: centralManager)

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
                                          rssi: 60)

        // Then
        XCTAssert(receivedDiscoveryChange.state.discoveredSorcs.contains(sorcID1))
        XCTAssertEqual(receivedDiscoveryChange.state.discoveredSorcs[sorcID1]!, SorcInfo(sorcID: sorcID1, discoveryDate: now, rssi: 60))
        XCTAssertEqual(receivedDiscoveryChange.action, .discovered(sorcID: sorcID1))
    }

    func test_centralManagerDidDiscoverPeripheral_ifManufacturerDataKeyIsNotSet_doesNotUpdateDiscoveredSorcs() {

        // Given
        centralManager.state = .poweredOn
        let connectionManager = ConnectionManager(centralManager: centralManager)
        connectionManager.startDiscovery()

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

    func test_centralManagerDidDiscoverPeripheral_ifSorcIsAlreadyDiscovered_updatesSorcInfo() {

        // Given
        let moment1 = Date(timeIntervalSince1970: 1)
        let systemClock = SystemClockMock(currentNow: moment1)
        let connectionManager = ConnectionManager(centralManager: centralManager, systemClock: systemClock)

        let peripheralA = CBPeripheralMock()

        prepareDiscoveredSorc(sorcID1, peripheral: peripheralA, connectionManager: connectionManager,
                              centralManager: centralManager, rssi: 40)

        let peripheralB = CBPeripheralMock()
        let strippedSorcID = sorcID1.replacingOccurrences(of: "-", with: "").dataFromHexadecimalString()!
        let advertisementData: [String: Any] = [
            CBAdvertisementDataManufacturerDataKey: strippedSorcID,
        ]

        var receivedDiscoveryChange: DiscoveryChange!
        _ = connectionManager.discoveryChange.subscribeNext { change in
            receivedDiscoveryChange = change
        }
        let moment2 = Date(timeIntervalSince1970: 2)
        systemClock.currentNow = moment2

        // When
        connectionManager.centralManager_(centralManager, didDiscover: peripheralB,
                                          advertisementData: advertisementData, rssi: 60)

        // Then
        XCTAssert(receivedDiscoveryChange.state.discoveredSorcs.contains(sorcID1))
        XCTAssertEqual(receivedDiscoveryChange.state.discoveredSorcs[sorcID1]!, SorcInfo(sorcID: sorcID1, discoveryDate: moment2, rssi: 60))
        XCTAssertEqual(receivedDiscoveryChange.action, .rediscovered(sorcID: sorcID1))
    }

    func test_centralManagerDidConnectPeripheral_ifItsConnectingAndPeripheralIsDiscovered_triesToDiscoverServicesOfPeripheral() {

        // Given
        let connectionManager = ConnectionManager(centralManager: centralManager)

        let peripheral = CBPeripheralMock()

        prepareConnectingSorc(sorcID1, peripheral: peripheral, connectionManager: connectionManager,
                              centralManager: centralManager)

        // When
        connectionManager.centralManager_(centralManager, didConnect: peripheral)

        // Then
        XCTAssertEqual(peripheral.discoverServicesCalledWithUUIDs!, [CBUUID(string: serviceID)])
    }

    func test_centralManagerDidConnectPeripheral_ifItsNotConnecting_doesNotTryToDiscoverServices() {

        // Given
        let connectionManager = ConnectionManager(centralManager: centralManager)

        let peripheral = CBPeripheralMock()

        // When
        connectionManager.centralManager_(centralManager, didConnect: peripheral)

        // Then
        XCTAssertNil(peripheral.discoverServicesCalledWithUUIDs)
    }

    func test_centralManagerDidFailToConnect_ifItsConnectingAndPeripheralIsDiscovered_connectionStateDisconnected() {

        // Given
        let connectionManager = ConnectionManager(centralManager: centralManager)

        let peripheral = CBPeripheralMock()

        prepareConnectingSorc(sorcID1, peripheral: peripheral, connectionManager: connectionManager,
                              centralManager: centralManager)

        var receivedConnectionChange: PhysicalConnectionChange!
        _ = connectionManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        connectionManager.centralManager_(centralManager, didFailToConnect: peripheral, error: nil)

        // Then
        let expected = PhysicalConnectionChange(state: .disconnected, action: .connectingFailed(sorcID: sorcID1))
        XCTAssertEqual(receivedConnectionChange, expected)
    }

    func test_centralManagerDidFailToConnect_ifItsNotConnecting_connectionStateNotUpdated() {

        // Given
        let connectionManager = ConnectionManager(centralManager: centralManager)

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
        let connectionManager = ConnectionManager(centralManager: centralManager)

        let peripheral = CBPeripheralMock()

        prepareConnectedSorc(sorcID1, peripheral: peripheral, connectionManager: connectionManager,
                             centralManager: centralManager)

        var receivedDiscoveryChange: DiscoveryChange!
        _ = connectionManager.discoveryChange.subscribeNext { change in
            receivedDiscoveryChange = change
        }

        var receivedConnectionChange: PhysicalConnectionChange!
        _ = connectionManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        connectionManager.centralManager_(centralManager, didDisconnectPeripheral: peripheral, error: nil)

        // Then
        XCTAssert(!receivedDiscoveryChange.state.discoveredSorcs.contains(sorcID1))
        XCTAssertEqual(receivedDiscoveryChange.action, .disconnected(sorcID: sorcID1))

        let expected = PhysicalConnectionChange(state: .disconnected, action: .connectionLost(sorcID: sorcID1))
        XCTAssertEqual(receivedConnectionChange, expected)
    }

    func test_centralManagerDidDisconnectPeripheral_ifItsNotConnected_doesNothing() {

        // Given
        let connectionManager = ConnectionManager(centralManager: centralManager)

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
        XCTAssert(receivedDiscoveryChange.state.discoveredSorcs.contains(sorcID1))
        XCTAssertEqual(receivedDiscoveryChange.action, .initial)

        if case .connecting = connectionManager.connectionChange.state {} else {
            XCTFail()
        }
    }

    func test_peripheralDidDiscoverServices_ifItsConnectingAndPeripheralIsDiscoveredAndErrorIsNil_triesToDiscoverCharacteristicsForService() {

        // Given
        let connectionManager = ConnectionManager(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        let service = CBServiceMock()
        peripheral.services_ = [service]

        prepareConnectingSorc(sorcID1, peripheral: peripheral, connectionManager: connectionManager,
                              centralManager: centralManager)

        // When
        connectionManager.peripheral_(peripheral, didDiscoverServices: nil)

        // Then
        if let arguments = peripheral.discoverCharacteristicsCalledWithArguments {
            XCTAssert(arguments.characteristicUUIDs!.contains(CBUUID(string: writeCharacteristicID)))
            XCTAssert(arguments.characteristicUUIDs!.contains(CBUUID(string: notifyCharacteristicID)))
        } else {
            XCTFail()
        }
    }

    func test_peripheralDidDiscoverServices_ifItsConnectingAndPeripheralIsDiscoveredAndErrorExists_connectingFailed() {

        // Given
        let connectionManager = ConnectionManager(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        let service = CBServiceMock()
        peripheral.services_ = [service]

        prepareConnectingSorc(sorcID1, peripheral: peripheral, connectionManager: connectionManager,
                              centralManager: centralManager)

        var receivedConnectionChange: PhysicalConnectionChange!
        _ = connectionManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        connectionManager.peripheral_(peripheral, didDiscoverServices: NSError(domain: "", code: 0, userInfo: nil))

        // Then
        let expected = PhysicalConnectionChange(state: .disconnected,
                                                action: .connectingFailed(sorcID: sorcID1))
        XCTAssertEqual(receivedConnectionChange, expected)
    }

    func test_peripheralDidDiscoverCharacteristics_ifItsConnectingAndPeripheralIsDiscoveredAndErrorIsNil_connectedAndSetNotifyValue() {

        // Given
        let connectionManager = ConnectionManager(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        let service = CBServiceMock()
        peripheral.services_ = [service]

        let writeCharacteristic = CBCharacteristicMock()
        writeCharacteristic.uuid = CBUUID(string: writeCharacteristicID)
        let notifyCharacteristic = CBCharacteristicMock()
        notifyCharacteristic.uuid = CBUUID(string: notifyCharacteristicID)
        service.characteristics_ = [writeCharacteristic, notifyCharacteristic]

        prepareConnectingSorc(sorcID1, peripheral: peripheral, connectionManager: connectionManager,
                              centralManager: centralManager)

        var receivedConnectionChange: PhysicalConnectionChange!
        _ = connectionManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        connectionManager.peripheral_(peripheral, didDiscoverCharacteristicsFor: service, error: nil)

        // Then
        let expected = PhysicalConnectionChange(state: .connected(sorcID: sorcID1),
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
        let connectionManager = ConnectionManager(centralManager: centralManager)
        let peripheral = CBPeripheralMock()
        let service = CBServiceMock()
        peripheral.services_ = [service]

        prepareConnectingSorc(sorcID1, peripheral: peripheral, connectionManager: connectionManager,
                              centralManager: centralManager)

        var receivedConnectionChange: PhysicalConnectionChange!
        _ = connectionManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        connectionManager.peripheral_(peripheral, didDiscoverCharacteristicsFor: service,
                                      error: NSError(domain: "", code: 0, userInfo: nil))

        // Then
        let expected = PhysicalConnectionChange(state: .disconnected,
                                                action: .connectingFailed(sorcID: sorcID1))
        XCTAssertEqual(receivedConnectionChange, expected)
    }

    func test_peripheralDidUpdateValue_ifNotifyCharacteristicAndErrorIsNil_dataReceivedSuccess() {

        // Given
        let connectionManager = ConnectionManager(centralManager: centralManager)
        let notifyCharacteristic = CBCharacteristicMock()
        notifyCharacteristic.value = Data(base64Encoded: "data")
        notifyCharacteristic.uuid = CBUUID(string: notifyCharacteristicID)

        var dataReceived: Data?
        _ = connectionManager.dataReceived.subscribeNext { result in
            if case let .success(data) = result {
                dataReceived = data
            }
        }

        // When
        connectionManager.peripheral_(CBPeripheralMock(), didUpdateValueFor: notifyCharacteristic, error: nil)

        // Then
        XCTAssertEqual(dataReceived, Data(base64Encoded: "data"))
    }

    func test_peripheralDidUpdateValue_ifNotifyCharacteristicAndErrorExists_dataReceivedError() {

        // Given
        let connectionManager = ConnectionManager(centralManager: centralManager)
        let notifyCharacteristic = CBCharacteristicMock()
        notifyCharacteristic.value = Data(base64Encoded: "data")
        notifyCharacteristic.uuid = CBUUID(string: notifyCharacteristicID)

        var dataReceivedError: Error?
        _ = connectionManager.dataReceived.subscribeNext { result in
            if case let .failure(error) = result {
                dataReceivedError = error
            }
        }

        let error = NSError(domain: "", code: 0, userInfo: nil)

        // When
        connectionManager.peripheral_(CBPeripheralMock(), didUpdateValueFor: notifyCharacteristic, error: error)

        // Then
        XCTAssertEqual(dataReceivedError! as NSError, error)
    }

    func test_peripheralDidWriteValue_ifWriteCharacteristicAndErrorIsNil_dataSentErrorIsNil() {

        // Given
        let connectionManager = ConnectionManager(centralManager: centralManager)
        let writeCharacteristic = CBCharacteristicMock()
        writeCharacteristic.uuid = CBUUID(string: writeCharacteristicID)

        var dataSentError: Error?
        _ = connectionManager.dataSent.subscribeNext { error in
            dataSentError = error
        }

        // When
        connectionManager.peripheral_(CBPeripheralMock(), didWriteValueFor: writeCharacteristic, error: nil)

        // Then
        XCTAssertNil(dataSentError)
    }

    func test_peripheralDidWriteValue_ifWriteCharacteristicAndErrorExists_dataSentErrorExists() {

        // Given
        let connectionManager = ConnectionManager(centralManager: centralManager)
        let writeCharacteristic = CBCharacteristicMock()
        writeCharacteristic.uuid = CBUUID(string: writeCharacteristicID)

        var dataSentError: Error?
        _ = connectionManager.dataSent.subscribeNext { error in
            dataSentError = error
        }

        let error = NSError(domain: "", code: 0, userInfo: nil)

        // When
        connectionManager.peripheral_(CBPeripheralMock(), didWriteValueFor: writeCharacteristic, error: error)

        // Then
        XCTAssertEqual(dataSentError! as NSError, error)
    }

    func test_filterTimerFired_ifDiscoveredSorcIsOutdatedAndNotConnected_removesIt() {

        // Given
        let systemClock = SystemClockMock(currentNow: Date(timeIntervalSince1970: 0))

        var fireTimer: (() -> Void)!
        let createTimer: ConnectionManager.CreateTimer = { block in
            fireTimer = block
            return Timer()
        }

        let connectionManager = ConnectionManager(
            centralManager: centralManager,
            systemClock: systemClock,
            createTimer: createTimer,
            appActivityStatusProvider: AppActivityStatusProvider(notificationCenter: NotificationCenter.default)
        )

        prepareDiscoveredSorc(sorcID1, peripheral: CBPeripheralMock(), connectionManager: connectionManager, centralManager: centralManager)

        // Moving system time forward 6 seconds, sorcOutdatedDurationSeconds == 5
        systemClock.currentNow = Date(timeIntervalSince1970: 6)

        // When
        fireTimer()

        // Then
        XCTAssert(!connectionManager.discoveryChange.state.discoveredSorcs.contains(sorcID1))
    }

    func test_filterTimerFired_ifDiscoveredSorcIsOutdatedAndConnected_keepsIt() {

        // Given
        let systemClock = SystemClockMock(currentNow: Date(timeIntervalSince1970: 0))

        var fireTimer: (() -> Void)!
        let createTimer: ConnectionManager.CreateTimer = { block in
            fireTimer = block
            return Timer()
        }

        let connectionManager = ConnectionManager(
            centralManager: centralManager,
            systemClock: systemClock,
            createTimer: createTimer,
            appActivityStatusProvider: AppActivityStatusProvider(notificationCenter: NotificationCenter.default)
        )

        prepareConnectedSorc(sorcID1, peripheral: CBPeripheralMock(), connectionManager: connectionManager, centralManager: centralManager)

        // Moving system time forward 6 seconds, sorcOutdatedDurationSeconds == 5
        systemClock.currentNow = Date(timeIntervalSince1970: 6)

        // When
        fireTimer()

        // Then
        XCTAssert(connectionManager.discoveryChange.state.discoveredSorcs.contains(sorcID1))
    }

    func test_appDidBecomeActive_ifCentralManagerIsPoweredOnAndDiscoveryIsEnabled_itScansForPeripheralsAllowingDuplicates() {

        // Given
        let appActivityStatusProvider = AppActivityStatusProviderMock()
        let connectionManager = ConnectionManager(
            centralManager: centralManager,
            appActivityStatusProvider: appActivityStatusProvider
        )
        startDiscovery(connectionManager: connectionManager, centralManager: centralManager)

        // When
        appActivityStatusProvider.appDidBecomeActiveSubject.onNext()

        // Then
        let arguments = centralManager.scanForPeripheralsCalledWithArguments!
        XCTAssertNil(arguments.serviceUUIDs)
        XCTAssertTrue(arguments.options![CBCentralManagerScanOptionAllowDuplicatesKey] as! Int == 1)
    }

    func test_appDidBecomeActive_ifCentralManagerIsPoweredOnAndDiscoveryIsNotEnabled_itDoesNothing() {

        // Given
        centralManager.state = .poweredOn
        let appActivityStatusProvider = AppActivityStatusProviderMock()
        _ = ConnectionManager(
            centralManager: centralManager,
            appActivityStatusProvider: appActivityStatusProvider
        )

        // When
        appActivityStatusProvider.appDidBecomeActiveSubject.onNext()

        // Then
        XCTAssertNil(centralManager.scanForPeripheralsCalledWithArguments)
    }

    private func startDiscovery(connectionManager: ConnectionManager, centralManager: CBCentralManagerMock) {
        centralManager.state = .poweredOn
        connectionManager.startDiscovery()
        centralManager.scanForPeripheralsCalledWithArguments = nil
    }

    private func prepareDiscoveredSorc(_ sorcID: SorcID, peripheral: CBPeripheralType,
                                       connectionManager: ConnectionManager, centralManager: CBCentralManagerMock,
                                       rssi: Int = 0) {

        startDiscovery(connectionManager: connectionManager, centralManager: centralManager)
        let strippedSorcID = sorcID.replacingOccurrences(of: "-", with: "").dataFromHexadecimalString()!
        let advertisementData: [String: Any] = [
            CBAdvertisementDataManufacturerDataKey: strippedSorcID,
        ]
        connectionManager.centralManager_(centralManager, didDiscover: peripheral, advertisementData: advertisementData,
                                          rssi: NSNumber(value: rssi))
    }

    private func prepareConnectingSorc(_ sorcID: SorcID, peripheral: CBPeripheralType,
                                       connectionManager: ConnectionManager, centralManager: CBCentralManagerMock) {

        prepareDiscoveredSorc(sorcID, peripheral: peripheral, connectionManager: connectionManager,
                              centralManager: centralManager)
        connectionManager.connectToSorc(sorcID)

        centralManager.connectCalledWithPeripheral = nil
    }

    private func prepareConnectedSorc(_ sorcID: SorcID, peripheral: CBPeripheralMock,
                                      connectionManager: ConnectionManager, centralManager: CBCentralManagerMock) {

        prepareDiscoveredSorc(sorcID, peripheral: peripheral, connectionManager: connectionManager,
                              centralManager: centralManager)
        connectionManager.connectToSorc(sorcID)
        connectionManager.centralManager_(centralManager, didConnect: peripheral)

        let service = CBServiceMock()
        peripheral.services_ = [service]
        connectionManager.peripheral_(peripheral, didDiscoverServices: nil)

        let notifyCharacteristic = CBCharacteristicMock()
        notifyCharacteristic.uuid = CBUUID(string: notifyCharacteristicID)
        let writeCharacteristic = CBCharacteristicMock()
        writeCharacteristic.uuid = CBUUID(string: writeCharacteristicID)
        service.characteristics_ = [notifyCharacteristic, writeCharacteristic]

        connectionManager.peripheral_(peripheral, didDiscoverCharacteristicsFor: service, error: nil)

        centralManager.connectCalledWithPeripheral = nil
    }
}
