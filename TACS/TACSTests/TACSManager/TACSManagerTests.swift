// TACSManagerTests.swift
// TACSTests

// Created on 25.04.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.

import Nimble
import Quick
import SecureAccessBLE
@testable import TACS

class TACSManagerTests: QuickSpec {
    // swiftlint:disable:next function_body_length
    override func spec() {
        var sorcManager: SorcManagerDefaultMock!
        var sut: TACSManager!
        var receivedConnectionChanges: [TACS.ConnectionChange]!
        var receivedDiscoveryChanges: [TACS.DiscoveryChange]!

        beforeEach {
            sorcManager = SorcManagerDefaultMock()
            let telematicsManager = TelematicsManagerDefaultMock()
            let vehicleAccessManager = VehicleAccessManagerDefaultMock()
            sut = TACSManager(sorcManager: sorcManager,
                              telematicsManager: telematicsManager,
                              vehicleAccessManager: vehicleAccessManager)
            receivedConnectionChanges = []
            _ = sut.connectionChange.subscribe { change in
                receivedConnectionChanges.append(change)
            }
            receivedDiscoveryChanges = []
            _ = sut.discoveryChange.subscribe { change in
                receivedDiscoveryChanges.append(change)
            }
        }
        describe("init") {
            it("should not be nil") {
                expect(sut).toNot(beNil())
            }
        }

        describe("scanForVehicle") {
            context("lease contains data for vehicle") {
                it("starts discovery") {
                    let vehicleRef = "4321"
                    sut.scanForVehicles(vehicleRefs: [vehicleRef], keyRing: TACSKeyRingFactory.validDefaultKeyRing())
                    expect(sorcManager.didReceiveStartDiscovery) == 1
                }
            }

            context("lease does not contain data for vehicle") {
                beforeEach {
                    let vehicleRef = "NOTEXISTING"
                    sut.scanForVehicles(vehicleRefs: [vehicleRef], keyRing: TACSKeyRingFactory.validDefaultKeyRing())
                }
                it("does not start discovery") {
                    expect(sorcManager.didReceiveStartDiscovery) == 0
                }
                it("notifies error") {
                    expect(receivedDiscoveryChanges).to(haveCount(2))
                    let expectedChange = TACS.DiscoveryChange(state: .init(discoveredVehicles: VehicleInfos()),
                                                              action: .missingBlobData(vehicleRef: "NOTEXISTING"))
                    expect(receivedDiscoveryChanges.last) == expectedChange
                }
            }

            context("discovery change with known sorc id") {
                it("notifies change with vehicle ref") {
                    let vehicleRef = "4321"
                    let keyRing = TACSKeyRingFactory.validDefaultKeyRing()
                    let date = Date()
                    let bleDiscoveryChange = BLEDiscoveryChangeFactory.discoveredChange(with: keyRing.sorcID(for: vehicleRef)!, date: date)

                    let expectedChange = TACSDiscoveryChangeFactory.discoveredChange(with: vehicleRef, date: date)
                    sut.scanForVehicles(vehicleRefs: [vehicleRef], keyRing: TACSKeyRingFactory.validDefaultKeyRing())
                    sorcManager.discoveryChangeSubject.onNext(bleDiscoveryChange)

                    expect(receivedDiscoveryChanges).to(haveCount(2))
                    expect(receivedDiscoveryChanges[1]) == expectedChange
                }
            }
        }

        describe("connectToVehicle") {
            context("lease contains data for vehicle") {
                it("starts connecting") {
                    let keyRing = TACSKeyRingFactory.validDefaultKeyRing()
                    let leaseTokenFromKeyRing = keyRing.tacsLeaseTokenTable.first!.leaseToken
                    let blobFromKeyRing = keyRing.tacsSorcBlobTable.first!.blob
                    let expectedToken = try! SecureAccessBLE.LeaseToken(id: leaseTokenFromKeyRing.leaseTokenId.uuidString,
                                                                        leaseID: leaseTokenFromKeyRing.leaseId.uuidString,
                                                                        sorcID: leaseTokenFromKeyRing.sorcId,
                                                                        sorcAccessKey: leaseTokenFromKeyRing.sorcAccessKey)
                    let expectedBlob = try! SecureAccessBLE.LeaseTokenBlob(messageCounter: Int(blobFromKeyRing.blobMessageCounter)!,
                                                                           data: blobFromKeyRing.blob)

                    sut.connect(vehicleAccessGrantId: keyRing.tacsLeaseTokenTable.first!.vehicleAccessGrantId, keyRing: keyRing)

                    expect(sorcManager.didReceiveConnectToSorc) == 1
                    expect(sorcManager.receivedConnectToSorcLeaseToken) == expectedToken
                    expect(sorcManager.receivedConnectToSorcLeaseTokenBlob) == expectedBlob
                }
            }
            context("lease does not contain data for vehicle") {
                var vehicleAccessGrantId: String!
                beforeEach {
                    vehicleAccessGrantId = "NOTEXISITNG"
                    let keyRing = TACSKeyRingFactory.validDefaultKeyRing()
                    sut.connect(vehicleAccessGrantId: vehicleAccessGrantId, keyRing: keyRing)
                }
                it("dose not start connecting") {
                    expect(sorcManager.didReceiveConnectToSorc) == 0
                }
                it("notifies error via change") {
                    let expectedChange = TACSConnectionChangeFactory.leaseDataErrorChange(vehicleAccessGrantId: vehicleAccessGrantId)
                    expect(receivedConnectionChanges).to(haveCount(2))
                    expect(receivedConnectionChanges[1]) == expectedChange
                }
            }
            context("on connection change") {
                context("sorcID matches active sorcID") {
                    it("notifies change for vehicle Ref") {
                        let keyRing = TACSKeyRingFactory.validDefaultKeyRing()
                        let sorcID = keyRing.tacsSorcBlobTable.first!.blob.sorcId
                        let vehicleRef = keyRing.tacsSorcBlobTable.first!.externalVehicleRef
                        let bleConnectionChange = SecureAccessBLE.ConnectionChange(state: .connecting(sorcID: sorcID, state: .physical),
                                                                                   action: .connect(sorcID: sorcID))

                        let expectedChange = TACS.ConnectionChange(state: .connecting(vehicleRef: vehicleRef, state: .physical),
                                                                   action: .connect(vehicleRef: vehicleRef))

                        sut.connect(vehicleAccessGrantId: keyRing.tacsLeaseTokenTable.first!.vehicleAccessGrantId, keyRing: keyRing)
                        sorcManager.connectionChangeSubject.onNext(bleConnectionChange)

                        expect(receivedConnectionChanges).to(haveCount(2))
                        expect(receivedConnectionChanges.last!) == expectedChange
                    }
                }
                context("sorcID does not match active sorcID") {
                    it("does not notify change") {
                        let vehicleRef = "4321"
                        let keyRing = TACSKeyRingFactory.validDefaultKeyRing()
                        sut.scanForVehicles(vehicleRefs: [vehicleRef], keyRing: keyRing)
                        let sorcID = SorcID(uuidString: "be2fecaf-734b-4252-8312-59d477200a20")!
                        let bleConnectionChange = SecureAccessBLE.ConnectionChange(state: .connecting(sorcID: sorcID, state: .physical),
                                                                                   action: .connect(sorcID: sorcID))
                        sorcManager.connectionChangeSubject.onNext(bleConnectionChange)
                        expect(receivedConnectionChanges).to(haveCount(1))
                    }
                }
            }
        }
    }
}
