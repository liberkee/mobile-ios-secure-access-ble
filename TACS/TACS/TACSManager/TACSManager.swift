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
    @available(*, deprecated: 1.0, message: "Use VehicleAccessManager or TelematicsManager instead.")
    public var sorcManager: SorcManagerType { return internalSorcManager }

    public let telematicsManager: TelematicsManagerType
    public let vehicleAccessManager: VehicleAccessManagerType

    // MARK: - BLE Interface

    /// The bluetooth enabled status
    public var isBluetoothEnabled: StateSignal<Bool> {
        return internalSorcManager.isBluetoothEnabled
    }

    // MARK: - Discovery

    private var activeSorcID: SorcID?
    private var activeVehicleRef: VehicleRef?

//    private var scanningVehicles: [VehicleRef: ]

//    private var tacsVehicleRefs: [VehicleRef: TACSVehicleReference] = [:]

    private var activeKeyRingForScan: TACSKeyRing?
    public func scanForVehicles(vehicleRefs: [VehicleRef], keyRing: TACSKeyRing) {
        activeKeyRingForScan = keyRing

//        tacsVehicleRefs.removeAll()
//        for tacsSorcBlobTableEntry in keyRing.tacsSorcBlobTable {
//            var tokens: [String: LeaseToken] = [:]
//            for leaseTokenTableEntry in keyRing.tacsLeaseTokenTable
//                where leaseTokenTableEntry.leaseToken.sorcId == tacsSorcBlobTableEntry.blob.sorcId {
//                    tokens[leaseTokenTableEntry.vehicleAccessGrantId] = leaseTokenTableEntry.leaseToken
//            }
//
//            let tacsVehicleReference = TACSVehicleReference(sorcID: tacsSorcBlobTableEntry.blob.sorcId,
//                                                            blob: tacsSorcBlobTableEntry.blob,
//                                                            keyholderID: tacsSorcBlobTableEntry.keyholderId,
//                                                            tokens: tokens)
//
//            tacsVehicleRefs[tacsSorcBlobTableEntry.externalVehicleRef] = tacsVehicleReference
//        }

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

//        if let blobTableEntry = keyRing.tacsSorcBlobTable.first(where: { $0.externalVehicleRef == vehicleRef }) {
        ////            activeVehicleRef = vehicleRef
        ////            guard let sorcID = SorcID(uuidString: blobTableEntry.blob.sorcId) else { return }
        ////            activeSorcID = sorcID
        ////            internalSorcManager.startDiscovery()
//        } else {
//            // Notify missing vehicle info via discovery chnage
        ////            let change = ConnectionChange(state: connectionChange.state, action: .connectingFailed(vehicleRef: vehicleRef, error: .leaseDataError))
        ////            connectionChangeSubject.onNext(change)
//        }
    }

    /// Stops discovery of all vehicles
    public func stopScanning() {
        activeKeyRingForScan = nil
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

    /// Connects to a SORC
    ///
    /// - Parameters:
    ///   - leaseToken: The lease token for the SORC
    ///   - leaseTokenBlob: The blob for the SORC
    public func connect(vehicleAccessGrantId: String, keyRing: TACSKeyRing) {
        guard let tacsLease = keyRing.tacsLeaseTokenTable.first(where: {
            $0.vehicleAccessGrantId == vehicleAccessGrantId
        })?.leaseToken else { return }

        // throws if sorcAccessKey is empty
        guard let leaseToken = try? SecureAccessBLE.LeaseToken(id: tacsLease.leaseTokenId.uuidString,
                                                               leaseID: tacsLease.leaseId.uuidString,
                                                               sorcID: tacsLease.sorcId,
                                                               sorcAccessKey: tacsLease.sorcAccessKey) else {
            return
        }

        guard let tacsBlob = keyRing.tacsSorcBlobTable.first(where: {
            $0.blob.sorcId == tacsLease.sorcId
        })?.blob else { return }
        guard let blob = try? SecureAccessBLE.LeaseTokenBlob(messageCounter: Int(tacsBlob.blobMessageCounter)!, data: tacsBlob.blob) else {
            return
        }
        internalSorcManager.connectToSorc(leaseToken: leaseToken, leaseTokenBlob: blob)
    }

    /**
     Disconnects from current SORC
     */
    public func disconnect() {
        internalSorcManager.disconnect()
    }

    init(sorcManager: SorcManagerType,
         telematicsManager: TelematicsManagerType,
         vehicleAccessManager: VehicleAccessManagerType) {
        internalSorcManager = sorcManager
        self.telematicsManager = telematicsManager
        self.vehicleAccessManager = vehicleAccessManager
        internalSorcManager.registerInterceptor(telematicsManager)
        internalSorcManager.registerInterceptor(vehicleAccessManager)
        subscribeToDiscoveryChanges()
        subscribeToConnectionChanges()
    }

    public convenience init() {
        let sorcManager = SorcManager()
        let telematicsManager = TelematicsManager(sorcManager: sorcManager)
        let vehicleAccessManager = VehicleAccessManager(sorcManager: sorcManager)
        self.init(sorcManager: sorcManager,
                  telematicsManager: telematicsManager,
                  vehicleAccessManager: vehicleAccessManager)
    }

    private func subscribeToConnectionChanges() {
        internalSorcManager.connectionChange.subscribe { [weak self] change in
            guard let strongSelf = self else { return }
            guard let activeSorcID = strongSelf.activeSorcID,
                let activeVehicleRef = strongSelf.activeVehicleRef else { return }
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
                let keyRing = strongSelf.activeKeyRingForScan else { return }
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
}

struct TACSVehicleReference {
    let sorcID: UUID
    let blob: LeaseTokenBlob
    let keyholderID: String?
    let tokens: [String: LeaseToken]
}
