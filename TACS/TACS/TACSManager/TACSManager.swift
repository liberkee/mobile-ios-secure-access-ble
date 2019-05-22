// TACSManager.swift
// TACS

// Created on 08.04.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.

import Foundation

import SecureAccessBLE

typealias SorcToVehicleRefMap = [SorcID: VehicleRef]

public class TACSManager {
    private let internalSorcManager: SorcManagerType
    private let disposeBag = DisposeBag()
    private let queue: DispatchQueue

    // Here we store sorc id and vehicle ref of currently active vehicle
    private var activeVehicle: (sorcID: SorcID, vehicleRef: VehicleRef, keyholderID: SorcID?)?
    private var activeKeyRing: TACSKeyRing?

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

    /// The bluetooth enabled status
    public var isBluetoothEnabled: StateSignal<Bool> {
        return internalSorcManager.isBluetoothEnabled
    }

    // MARK: - Discovery

    public func scanForVehicles(vehicleRefs: [VehicleRef], keyRing: TACSKeyRing) {
        queue.async { [weak self] in
            self?.scanForVehiclesInternal(vehicleRefs: vehicleRefs, keyRing: keyRing)
        }
    }

    internal func scanForVehiclesInternal(vehicleRefs: [VehicleRef], keyRing: TACSKeyRing) {
        activeKeyRing = keyRing
        var foundVehicleWithMatchingSorcID = false
        vehicleRefs.forEach { ref in
            if keyRing.sorcID(for: ref) != nil {
                foundVehicleWithMatchingSorcID = true
            } else {
                // notify missing value in key ring
                let change = DiscoveryChange(state: discoveryChange.state, action: .missingBlobData(vehicleRef: ref))
                discoveryChangeSubject.onNext(change)
            }
        }

        if foundVehicleWithMatchingSorcID {
            // some sorc ids found, start scanning
            internalSorcManager.startDiscovery()
        }
    }

    /// Stops discovery of all vehicles
    public func stopScanning() {
        queue.async { [weak self] in
            self?.stopScanningInternal()
        }
    }

    internal func stopScanningInternal() {
        internalSorcManager.stopDiscovery()
    }

    private let discoveryChangeSubject = ChangeSubject<DiscoveryChange>(state: .init(discoveredVehicles: VehicleInfos()))

    /// The state of SORC discovery with the action that led to this state
    public var discoveryChange: ChangeSignal<DiscoveryChange> {
        return discoveryChangeSubject.asSignal()
    }

    // MARK: - Connection

    private let connectionChangeSubject = ChangeSubject<ConnectionChange>(state: .disconnected)
    /// The state of the connection with the action that led to this state
    public var connectionChange: ChangeSignal<ConnectionChange> {
        return connectionChangeSubject.asSignal()
    }

    /// Connects to a vehicle if key ring contains necessary data for given `vehicleAccessGrantId`.
    /// If key ring does not contain necessary data, the error will be notified via `connectionChange`.
    ///
    /// - Parameters:
    ///   - vehicleAccessGrantId: Vehicle access grant id
    ///   - keyRing: Key ring containing necessary key data
    public func connect(vehicleAccessGrantId: String, keyRing: TACSKeyRing) {
        queue.async { [weak self] in
            self?.connectInternal(vehicleAccessGrantId: vehicleAccessGrantId, keyRing: keyRing)
        }
    }

    internal func connectInternal(vehicleAccessGrantId: String, keyRing: TACSKeyRing) {
        activeKeyRing = keyRing
        guard let tacsLease = keyRing.leaseToken(for: vehicleAccessGrantId),
            let tacsBlobData = keyRing.blobData(for: tacsLease.sorcId) else {
            // blob data error
            let connectionChange = ConnectionChange(state: connectionChangeSubject.state,
                                                    action: .connectingFailedDataMissing(vehicleAccessGrantId: vehicleAccessGrantId))
            connectionChangeSubject.onNext(connectionChange)
            return
        }

        // throws if sorcAccessKey is empty
        guard let leaseToken = try? SecureAccessBLE.LeaseToken(id: tacsLease.leaseTokenId.uuidString,
                                                               leaseID: tacsLease.leaseId.uuidString,
                                                               sorcID: tacsLease.sorcId,
                                                               sorcAccessKey: tacsLease.sorcAccessKey) else {
            return
        }

        let tacsBlob = tacsBlobData.blob
        guard let blob = try? SecureAccessBLE.LeaseTokenBlob(messageCounter: Int(tacsBlob.blobMessageCounter)!, data: tacsBlob.blob) else {
            return
        }

        activeVehicle = (tacsLease.sorcId, tacsBlobData.externalVehicleRef, tacsBlobData.keyholderId)
        internalSorcManager.connectToSorc(leaseToken: leaseToken, leaseTokenBlob: blob)
    }

    /**
     Disconnects from current SORC
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
        (self.keyholderManager as? KeyholderManager)?.keyhodlerIDProvider = { self.activeVehicle?.keyholderID }
        internalSorcManager.registerInterceptor(telematicsManager)
        internalSorcManager.registerInterceptor(vehicleAccessManager)
        subscribeToDiscoveryChanges()
        subscribeToConnectionChanges()
    }

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
            guard let strongSelf = self else { return }
            guard let activeSorcID = strongSelf.activeVehicle?.sorcID,
                let activeVehicleRef = strongSelf.activeVehicle?.vehicleRef else { return }
            guard let transformedChange = try? ConnectionChange(from: change, activeSorcID: activeSorcID, activeVehicleRef: activeVehicleRef) else {
                // Is this case possible? We get a change for a sorcID we did not ask to connect to.
                return
            }
            strongSelf.connectionChangeSubject.onNext(transformedChange)
        }.disposed(by: disposeBag)
    }

    private func subscribeToDiscoveryChanges() {
        internalSorcManager.discoveryChange.subscribe { [weak self] change in
            guard let strongSelf = self,
                let keyRing = strongSelf.activeKeyRing else { return }
            guard let transformedChange = try? TACS.DiscoveryChange(from: change, sorcToVehicleRefMap: keyRing.sorcToVehicleRefDict()) else {
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

    func sorcToVehicleRefDict() -> SorcToVehicleRefMap {
        var result: SorcToVehicleRefMap = [:]
        tacsSorcBlobTable.forEach {
            result[$0.blob.sorcId] = $0.externalVehicleRef
        }
        return result
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
