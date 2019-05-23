// TACSManager.swift
// TACS

// Created on 08.04.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.

import Foundation

import SecureAccessBLE

typealias SorcToVehicleRefMap = [SorcID: VehicleRef]

struct ActiveVehicleSetup {
    let keyring: TACSKeyRing
    let saLeaseToken: SecureAccessBLE.LeaseToken
    let saBlob: SecureAccessBLE.LeaseTokenBlob
    let sorcId: SorcID
    let extenralVehicleRef: String
    let keyholderId: UUID?
}

/// TACSManager, the main entry point of the TACS SDK.
public class TACSManager {
    private let internalSorcManager: SorcManagerType
    private let disposeBag = DisposeBag()
    private let queue: DispatchQueue

    // Queue for read/write active vehicle setup to make it thread safe
    private let keyRingSavingQueue = DispatchQueue(label: "com.hufsm.ble.keyRingSaver")
    private var activeVehicleSetupUnsafe: ActiveVehicleSetup?
    private var activeVehicleSetup: ActiveVehicleSetup? {
        get {
            return keyRingSavingQueue.sync { activeVehicleSetupUnsafe }
        }
        set {
            keyRingSavingQueue.sync {
                activeVehicleSetupUnsafe = newValue
            }
        }
    }

    /// :nodoc:
    @available(*, deprecated: 1.0, message: "Use VehicleAccessManager or TelematicsManager instead.")
    public var sorcManager: SorcManagerType { return internalSorcManager }

    /// Telematics manager which can be used to get telematics data from the vehicle
    public let telematicsManager: TelematicsManagerType
    /// Vehicle access manager which can be used to control vehicle access
    public let vehicleAccessManager: VehicleAccessManagerType
    /// Keyholder manager which can be used to retrieve keyholder status
    public let keyholderManager: KeyholderManagerType

    // MARK: - BLE Interface

    /// The status of bluetooth device.
    public var isBluetoothEnabled: StateSignal<Bool> {
        return internalSorcManager.isBluetoothEnabled
    }

    // MARK: - Set up keyring and grant

    /// Configures manager for usage with specified `vehicleAccessGrantId` and `keyRing`.
    /// Call this method before performing any actions on manager.
    ///
    /// - Parameters:
    ///   - vehicleAccessGrantId: VehicleAccessGrantId which should be used.
    ///   - keyRing: Key ring which should be used. Must contain lease data for given `vehicleAccessGrantId`.
    /// - Returns: `true` if the setup succeeded, `false` if necessary data could not be retrieved from keyring.
    public func useAccessGrant(with vehicleAccessGrantId: String, from keyRing: TACSKeyRing) -> Bool {
        guard let tacsLease = keyRing.leaseToken(for: vehicleAccessGrantId),
            let tacsBlobData = keyRing.blobData(for: tacsLease.sorcId) else {
            // blob data error
            return false
        }

        // throws if sorcAccessKey is empty
        guard let leaseToken = try? SecureAccessBLE.LeaseToken(id: tacsLease.leaseTokenId.uuidString,
                                                               leaseID: tacsLease.leaseId.uuidString,
                                                               sorcID: tacsLease.sorcId,
                                                               sorcAccessKey: tacsLease.sorcAccessKey) else {
            return false
        }

        let tacsBlob = tacsBlobData.blob
        guard let blob = try? SecureAccessBLE.LeaseTokenBlob(messageCounter: Int(tacsBlob.blobMessageCounter)!, data: tacsBlob.blob) else {
            return false
        }

        let setup = ActiveVehicleSetup(keyring: keyRing,
                                       saLeaseToken: leaseToken,
                                       saBlob: blob,
                                       sorcId: tacsLease.sorcId,
                                       extenralVehicleRef: tacsBlobData.externalVehicleRef,
                                       keyholderId: tacsBlobData.keyholderId)
        activeVehicleSetup = setup
        return true
    }

    /// Resets the manager state. Disconnects from vehicle, stops scanning and resets
    /// lease data which was previously set up via `useAccessGrant(with: from:)`
    public func reset() {
        queue.async { [weak self] in
            self?.stopScanningInternal()
            self?.activeVehicleSetup = nil
        }
    }

    // MARK: - Discovery

    /// Starts BLE discovery. Changes will be notified via `discoveryChange`.
    public func startScanning() {
        queue.async { [weak self] in
            self?.scanInternal()
        }
    }

    internal func scanInternal() {
        guard activeVehicleSetup != nil else {
            let change = DiscoveryChange(state: discoveryChange.state, action: .missingBlobData)
            discoveryChangeSubject.onNext(change)
            return
        }
        internalSorcManager.startDiscovery()
    }

    /// Stops BLE discovery. Changes will be notified via `discoveryChange`.
    public func stopScanning() {
        queue.async { [weak self] in
            self?.stopScanningInternal()
        }
    }

    internal func stopScanningInternal() {
        internalSorcManager.stopDiscovery()
    }

    private let discoveryChangeSubject = ChangeSubject<DiscoveryChange>(state: .init(discoveredVehicles: VehicleInfos()))

    /// The state of vehicle discovery with the action that led to this state.
    public var discoveryChange: ChangeSignal<DiscoveryChange> {
        return discoveryChangeSubject.asSignal()
    }

    // MARK: - Connection

    private let connectionChangeSubject = ChangeSubject<ConnectionChange>(state: .disconnected)
    /// The state of the connection with the action that led to this state
    public var connectionChange: ChangeSignal<ConnectionChange> {
        return connectionChangeSubject.asSignal()
    }

    /// Starts connecting to vehicle if the keyring and accessGrantId was set before.
    public func connect() {
        queue.async { [weak self] in
            self?.connectInternal()
        }
    }

    internal func connectInternal() {
        guard let activeVehicleSetup = self.activeVehicleSetup else {
            // blob data error
            let connectionChange = ConnectionChange(state: connectionChangeSubject.state,
                                                    action: .connectingFailedDataMissing)
            connectionChangeSubject.onNext(connectionChange)
            return
        }

        internalSorcManager.connectToSorc(leaseToken: activeVehicleSetup.saLeaseToken,
                                          leaseTokenBlob: activeVehicleSetup.saBlob)
    }

    /**
     Disconnects from current vehicle
     */
    public func disconnect() {
        queue.async { [weak self] in
            self?.disconnectInternal()
        }
    }

    internal func disconnectInternal() {
        internalSorcManager.disconnect()
    }

    init(sorcManager: SorcManagerType,
         telematicsManager: TelematicsManagerType,
         vehicleAccessManager: VehicleAccessManagerType,
         keyholderManager: KeyholderManagerType,
         queue: DispatchQueue) {
        internalSorcManager = sorcManager
        self.telematicsManager = telematicsManager
        self.vehicleAccessManager = vehicleAccessManager
        self.keyholderManager = keyholderManager
        self.queue = queue
        (self.keyholderManager as? KeyholderManager)?.keyholderIDProvider = { self.activeVehicleSetup?.keyholderId }
        internalSorcManager.registerInterceptor(telematicsManager)
        internalSorcManager.registerInterceptor(vehicleAccessManager)
        subscribeToDiscoveryChanges()
        subscribeToConnectionChanges()
    }

    /// Creates instance of `TACSManager`. Only one reference should be used.
    ///
    /// - Parameter queue: Optional queue which will be used to do the related work.
    ///
    /// Changes of all managers (`TACSManager`, `VehicleAccessManager`, `TelematicsManager` and `KeyholderManager`)
    /// will notify events on the provided queue with one exception: Initial actions are notified on the same queue
    /// where the subscription (call to `subscribe`) happens.
    /// If the queue is not provided, the main queue will be used.
    public convenience init(queue: DispatchQueue = DispatchQueue.main) {
        let sorcManager = SorcManager(queue: queue)
        let telematicsManager = TelematicsManager(sorcManager: sorcManager, queue: queue)
        let vehicleAccessManager = VehicleAccessManager(sorcManager: sorcManager, queue: queue)
        let keyholderManager = KeyholderManager(queue: queue)
        self.init(sorcManager: sorcManager,
                  telematicsManager: telematicsManager,
                  vehicleAccessManager: vehicleAccessManager,
                  keyholderManager: keyholderManager,
                  queue: queue)
    }

    private func subscribeToConnectionChanges() {
        internalSorcManager.connectionChange.subscribe { [weak self] change in
            guard let strongSelf = self,
                let activeVehicleSetup = strongSelf.activeVehicleSetup else { return }
            guard let transformedChange = try? ConnectionChange(from: change,
                                                                activeSorcID: activeVehicleSetup.sorcId,
                                                                activeVehicleRef: activeVehicleSetup.extenralVehicleRef) else {
                // Is this case possible? We get a change for a sorcID we did not ask to connect to.
                return
            }
            strongSelf.connectionChangeSubject.onNext(transformedChange)
        }.disposed(by: disposeBag)
    }

    private func subscribeToDiscoveryChanges() {
        internalSorcManager.discoveryChange.subscribe { [weak self] change in
            guard let strongSelf = self, let activeVehicleSetup = strongSelf.activeVehicleSetup else { return }
            let sorcToVehicleRefMap = [activeVehicleSetup.sorcId: activeVehicleSetup.extenralVehicleRef]
            guard let transformedChange = try? TACS.DiscoveryChange(from: change,
                                                                    sorcToVehicleRefMap: sorcToVehicleRefMap) else {
                return
            }
            strongSelf.discoveryChangeSubject.onNext(transformedChange)
        }.disposed(by: disposeBag)
    }
}

extension TACSKeyRing {
    func sorcID(for vehicleRef: VehicleRef) -> SorcID? {
        guard let blobTableEntry = tacsSorcBlobTable.first(where: { $0.externalVehicleRef == vehicleRef }) else {
            return nil
        }
        return blobTableEntry.blob.sorcId
    }

    func leaseToken(for vehicleAccessGrantId: String) -> LeaseToken? {
        return tacsLeaseTokenTable.first(where: {
            $0.vehicleAccessGrantId == vehicleAccessGrantId
        })?.leaseToken
    }

    func blobData(for sorcID: SorcID) -> TacsSorcBlobTableEntry? {
        return tacsSorcBlobTable.first(where: {
            $0.blob.sorcId == sorcID
        })
    }
}
