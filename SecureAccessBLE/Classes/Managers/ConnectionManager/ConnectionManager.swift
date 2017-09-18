//
//  ConnectionManager.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import CoreBluetooth
import CommonUtils

private class DiscoveredSorc {

    let sorcID: SorcID
    var peripheral: CBPeripheralType
    let discoveryDate: Date
    let rssi: Int

    init(sorcID: SorcID, peripheral: CBPeripheralType, discoveryDate: Date, rssi: Int) {
        self.sorcID = sorcID
        self.peripheral = peripheral
        self.discoveryDate = discoveryDate
        self.rssi = rssi
    }
}

private extension SorcInfo {

    init(discoveredSorc: DiscoveredSorc) {
        sorcID = discoveredSorc.sorcID
        discoveryDate = discoveredSorc.discoveryDate
        rssi = discoveredSorc.rssi
    }
}

private extension CBManagerState {

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

/// Manages the discovery and connection of SORCs
class ConnectionManager: NSObject, ConnectionManagerType, BluetoothStatusProviderType, ScannerType {

    let isBluetoothEnabled: BehaviorSubject<Bool>
    let discoveryChange = ChangeSubject<DiscoveryChange>(state: .init(
        discoveredSorcs: SorcInfos(),
        discoveryIsEnabled: false
    ))
    let connectionChange = ChangeSubject<PhysicalConnectionChange>(state: .disconnected)

    let dataSent = PublishSubject<Error?>()
    let dataReceived = PublishSubject<Result<Data>>()

    fileprivate let configuration: Configuration

    fileprivate var writeCharacteristicID: String {
        return configuration.writeCharacteristicID
    }

    fileprivate var notifyCharacteristicID: String {
        return configuration.notifyCharacteristicID
    }

    fileprivate var writeCharacteristic: CBCharacteristicType?
    fileprivate var notifyCharacteristic: CBCharacteristicType?

    private var centralManager: CBCentralManagerType!
    fileprivate let systemClock: SystemClockType

    /// Timer to remove outdated discovered SORCs
    fileprivate var filterTimer: Timer?

    private let appActivityStatusProvider: AppActivityStatusProviderType

    /// The SORCs that were discovered and were not removed by the filterTimer
    fileprivate var discoveredSorcs = [SorcID: DiscoveredSorc]()

    private let disposeBag = DisposeBag()

    fileprivate var connectedSorc: DiscoveredSorc? {
        if case let .connected(sorcID) = connectionState {
            return discoveredSorcs[sorcID]
        }
        return nil
    }

    fileprivate var connectionState: PhysicalConnectionChange.State {
        return connectionChange.state
    }

    required init(
        centralManager: CBCentralManagerType,
        systemClock: SystemClockType,
        createTimer: CreateTimer,
        appActivityStatusProvider: AppActivityStatusProviderType,
        configuration: Configuration = Configuration()
    ) {

        self.systemClock = systemClock
        isBluetoothEnabled = BehaviorSubject(value: centralManager.state == .poweredOn)
        self.appActivityStatusProvider = appActivityStatusProvider
        self.configuration = configuration
        super.init()

        self.centralManager = centralManager
        centralManager.delegate = self

        filterTimer = createTimer(removeOutdatedSorcs)

        _ = appActivityStatusProvider.appDidBecomeActive.subscribe { [weak self] in
            self?.handleAppDidBecomeActive()
        }
    }

    deinit {
        disconnect()
        filterTimer?.invalidate()
    }

    func startDiscovery() {
        updateDiscoveryChange(action: .startDiscovery)
        guard centralManager.state == .poweredOn else { return }
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: 1])
    }

    func stopDiscovery() {
        centralManager.stopScan()
        updateDiscoveryChange(action: .stopDiscovery)
    }

    /// If a connection to an undiscovered SORC is tried it fails silently.
    func connectToSorc(_ sorcID: SorcID) {
        guard let peripheral = peripheralMatchingSorcID(sorcID) else {
            debugPrint("ConnectionManager: Try to connect to SORC that is not discovered.")
            return
        }
        switch connectionState {
        case let .connecting(currentSorcID):
            if currentSorcID != sorcID {
                disconnect()
                connectionChange.onNext(.init(state: .connecting(sorcID: sorcID), action: .connect(sorcID: sorcID)))
            }
            centralManager.connect(peripheral, options: nil)
        case let .connected(currentSorcID):
            if currentSorcID != sorcID {
                disconnect()
                connectionChange.onNext(.init(state: .connecting(sorcID: sorcID), action: .connect(sorcID: sorcID)))
                centralManager.connect(peripheral, options: nil)
            }
        case .disconnected:
            connectionChange.onNext(.init(state: .connecting(sorcID: sorcID), action: .connect(sorcID: sorcID)))
            centralManager.connect(peripheral, options: nil)
        }
    }

    func disconnect() {
        disconnect(withAction: nil)
    }

    func sendData(_ data: Data) {
        guard case let .connected(sorcID) = connectionState,
            let characteristic = writeCharacteristic,
            let peripheral = peripheralMatchingSorcID(sorcID) else { return }

        peripheral.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
    }

    // MARK: - Private methods

    fileprivate func disconnect(withAction action: PhysicalConnectionChange.Action?) {
        switch connectionState {
        case let .connecting(sorcID), let .connected(sorcID):
            if let peripheral = peripheralMatchingSorcID(sorcID) {
                centralManager.cancelPeripheralConnection(peripheral)
            }
            discoveredSorcs[sorcID] = nil
            updateDiscoveryChange(action: .disconnect(sorcID: sorcID))
            writeCharacteristic = nil
            notifyCharacteristic = nil
            connectionChange.onNext(.init(state: .disconnected, action: action ?? .disconnect(sorcID: sorcID)))
        case .disconnected: break
        }
    }

    private func handleAppDidBecomeActive() {
        if discoveryChange.state.discoveryIsEnabled {
            startDiscovery()
        }
    }

    private func removeOutdatedSorcs() {
        let outdatedSorcs = Array(discoveredSorcs.values).filter { (sorc) -> Bool in
            let discoveredAgoInterval = systemClock.timeIntervalSinceNow(for: sorc.discoveryDate)
            let outdated = discoveredAgoInterval < -configuration.sorcOutdatedDuration
            return outdated && sorc.sorcID != self.connectedSorc?.sorcID
        }
        let outdatedSorcIDs = outdatedSorcs.map { $0.sorcID }
        if outdatedSorcIDs.count > 0 {
            for sorcID in outdatedSorcIDs {
                discoveredSorcs[sorcID] = nil
            }
            updateDiscoveryChange(action: .lost(sorcIDs: Set(outdatedSorcIDs)))
        }
    }

    fileprivate func updateDiscoveredSorcsWithNewSorc(_ sorc: DiscoveredSorc) {
        if let connectedSorc = connectedSorc, sorc.sorcID == connectedSorc.sorcID {
            sorc.peripheral = connectedSorc.peripheral
        }
        let replaced = discoveredSorcs.updateValue(sorc, forKey: sorc.sorcID) != nil
        let action: DiscoveryChange.Action = replaced ?
            .rediscovered(sorcID: sorc.sorcID) : .discovered(sorcID: sorc.sorcID)
        updateDiscoveryChange(action: action)
    }

    fileprivate func resetDiscoveredSorcs() {
        discoveredSorcs = [:]
        updateDiscoveryChange(action: .reset)
    }

    fileprivate func updateDiscoveryChange(action: DiscoveryChange.Action) {
        let state = discoveryChange.state
        switch action {
        case .startDiscovery:
            guard !state.discoveryIsEnabled else { return }
            discoveryChange.onNext(.init(
                state: state.withDiscoveryIsEnabled(true),
                action: action
            ))
        case .stopDiscovery:
            guard state.discoveryIsEnabled else { return }
            discoveryChange.onNext(.init(
                state: state.withDiscoveryIsEnabled(false),
                action: action
            ))
        default:
            var sorcInfos = SorcInfos()
            for sorc in discoveredSorcs.values {
                let sorcInfo = SorcInfo(discoveredSorc: sorc)
                sorcInfos[sorcInfo.sorcID] = sorcInfo
            }
            discoveryChange.onNext(.init(
                state: .init(discoveredSorcs: sorcInfos, discoveryIsEnabled: state.discoveryIsEnabled),
                action: action
            ))
        }
    }

    fileprivate func peripheralMatchingSorcID(_ sorcID: SorcID) -> CBPeripheralType? {
        return discoveredSorcs[sorcID]?.peripheral
    }
}

extension ConnectionManager {

    convenience init(configuration: ConnectionManager.Configuration = Configuration()) {

        let centralManager = CBCentralManager(delegate: nil, queue: nil,
                                              options: [CBPeripheralManagerOptionShowPowerAlertKey: 0])

        let systemClock = SystemClock()

        let createTimer: ConnectionManager.CreateTimer = { block in
            Timer(
                timeInterval: configuration.removeOutdatedSorcsInterval,
                repeats: true,
                block: { _ in block() }
            )
        }

        let appActivityStatusProvider = AppActivityStatusProvider(notificationCenter: NotificationCenter.default)

        self.init(
            centralManager: centralManager,
            systemClock: systemClock,
            createTimer: createTimer,
            appActivityStatusProvider: appActivityStatusProvider,
            configuration: configuration
        )
    }
}

// MARK: - CBCentralManagerDelegate_

extension ConnectionManager {

    func centralManagerDidUpdateState_(_ central: CBCentralManagerType) {
        consoleLog("ConnectionManager Central updated state: \(central.state)")

        isBluetoothEnabled.onNext(central.state == .poweredOn)

        if central.state == .poweredOn {
            if discoveryChange.state.discoveryIsEnabled {
                startDiscovery()
            }
        } else {
            resetDiscoveredSorcs()
        }
    }

    func centralManager_(_: CBCentralManagerType, didDiscover peripheral: CBPeripheralType,
                         advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard discoveryChange.state.discoveryIsEnabled,
            let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
            let sorcID = UUID(data: manufacturerData) else { return }

        let sorc = DiscoveredSorc(sorcID: sorcID, peripheral: peripheral, discoveryDate: systemClock.now(), rssi: RSSI.intValue)
        updateDiscoveredSorcsWithNewSorc(sorc)
    }

    func centralManager_(_: CBCentralManagerType, didConnect peripheral: CBPeripheralType) {
        consoleLog("Central connected to peripheral: \(peripheral.identifier.uuidString)")

        guard case let .connecting(sorcID) = connectionState,
            peripheralMatchingSorcID(sorcID)?.identifier == peripheral.identifier else { return }

        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: configuration.serviceID)])
    }

    func centralManager_(_: CBCentralManagerType, didFailToConnect peripheral: CBPeripheralType, error: Error?) {
        consoleLog("Central failed connecting to peripheral: \(error?.localizedDescription ?? "Unknown error")")

        guard case let .connecting(sorcID) = connectionState,
            peripheralMatchingSorcID(sorcID)?.identifier == peripheral.identifier else { return }

        connectionChange.onNext(.init(state: .disconnected, action: .connectingFailed(sorcID: sorcID)))
    }

    func centralManager_(_: CBCentralManagerType, didDisconnectPeripheral peripheral: CBPeripheralType,
                         error: Error?) {

        consoleLog("Central didDisconnectPeripheral: \(error?.localizedDescription ?? "Unknown error")")

        switch connectionState {
        case let .connecting(sorcID), let .connected(sorcID):
            guard peripheralMatchingSorcID(sorcID)?.identifier == peripheral.identifier else { return }

            consoleLog("Central didDisconnectPeripheral2")

            discoveredSorcs[sorcID] = nil
            updateDiscoveryChange(action: .disconnected(sorcID: sorcID))
            connectionChange.onNext(.init(state: .disconnected, action: .connectionLost(sorcID: sorcID)))
        default: break
        }
    }
}

// MARK: - CBPeripheralDelegate_

extension ConnectionManager {

    func peripheral_(_ peripheral: CBPeripheralType, didDiscoverServices error: Error?) {

        guard case let .connecting(sorcID) = connectionState,
            peripheralMatchingSorcID(sorcID)?.identifier == peripheral.identifier else { return }

        if error != nil {
            disconnect(withAction: .connectingFailed(sorcID: sorcID))
        } else {
            for service in peripheral.services_! {
                let characteristics = [CBUUID(string: writeCharacteristicID), CBUUID(string: notifyCharacteristicID)]
                peripheral.discoverCharacteristics(characteristics, for: service)
            }
        }
    }

    func peripheral_(_ peripheral: CBPeripheralType, didDiscoverCharacteristicsFor service: CBServiceType,
                     error: Error?) {

        guard case let .connecting(sorcID) = connectionState,
            peripheralMatchingSorcID(sorcID)?.identifier == peripheral.identifier else { return }

        if error != nil {
            disconnect(withAction: .connectingFailed(sorcID: sorcID))
        } else {
            for characteristic in service.characteristics_! {
                if characteristic.uuid == CBUUID(string: notifyCharacteristicID) {
                    notifyCharacteristic = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                } else if characteristic.uuid == CBUUID(string: writeCharacteristicID) {
                    writeCharacteristic = characteristic
                }
            }
        }

        if writeCharacteristic != nil && notifyCharacteristic != nil {
            connectionChange.onNext(.init(state: .connected(sorcID: sorcID),
                                          action: .connectionEstablished(sorcID: sorcID)))
        }
    }

    func peripheral_(_: CBPeripheralType, didUpdateValueFor characteristic: CBCharacteristicType, error: Error?) {
        guard characteristic.uuid == CBUUID(string: notifyCharacteristicID) else { return }
        if let error = error {
            dataReceived.onNext(.failure(error))
        } else if let data = characteristic.value {
            dataReceived.onNext(.success(data))
        } else {
            debugPrint("ConnectionManager: No error but characteristic value was nil which is unexpected.")
        }
    }

    func peripheral_(_: CBPeripheralType, didWriteValueFor characteristic: CBCharacteristicType, error: Error?) {
        guard characteristic.uuid == CBUUID(string: writeCharacteristicID) else { return }
        dataSent.onNext(error)
    }
}
