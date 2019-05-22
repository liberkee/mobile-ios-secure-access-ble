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
            let keyholderManager = KeyholderManagerDefaultMock()
            sut = TACSManager(sorcManager: sorcManager,
                              telematicsManager: telematicsManager,
                              vehicleAccessManager: vehicleAccessManager,
                              keyholderManager: keyholderManager,
                              queue: DispatchQueue(label: "com.queue.ble"))
            receivedConnectionChanges = []
            _ = sut.connectionChange.subscribe { change in
                receivedConnectionChanges.append(change)
            }
            receivedDiscoveryChanges = []
            _ = sut.discoveryChange.subscribe { change in
                receivedDiscoveryChanges.append(change)
            }
        }

        describe("use grant from keyring") {
            context("lease contains data for grant") {
                it("succeeds") {
                    let keyRing = TACSKeyRingFactory.validDefaultKeyRing()
                    let grantID = keyRing.tacsLeaseTokenTable.first!.vehicleAccessGrantId
                    let result = sut.useAccessGrant(with: grantID, from: keyRing)
                    expect(result) == true
                }
            }
            context("lease does not contain data for grant") {
                it("fails") {
                    let keyRing = TACSKeyRingFactory.validDefaultKeyRing()
                    let grantID = "Not existing"
                    let result = sut.useAccessGrant(with: grantID, from: keyRing)
                    expect(result) == false
                }
            }
        }

        describe("scan") {
            context("active vehicle set") {
                it("starts discovery") {
                    let keyRing = TACSKeyRingFactory.validDefaultKeyRing()
                    let grantID = keyRing.tacsLeaseTokenTable.first!.vehicleAccessGrantId
                    _ = sut.useAccessGrant(with: grantID, from: keyRing)
                    sut.scanInternal()
                    expect(sorcManager.didReceiveStartDiscovery) == 1
                }
            }

            context("lease does not contain data for vehicle") {
                beforeEach {
                    sut.scanInternal()
                }
                it("does not start discovery") {
                    expect(sorcManager.didReceiveStartDiscovery) == 0
                }
                it("notifies error") {
                    expect(receivedDiscoveryChanges).to(haveCount(2))
                    let expectedChange = TACS.DiscoveryChange(state: .init(discoveredVehicles: VehicleInfos()),
                                                              action: .missingBlobData)
                    expect(receivedDiscoveryChanges.last) == expectedChange
                }
            }

            context("discovery change with known sorc id") {
                it("notifies change") {
                    let keyRing = TACSKeyRingFactory.validDefaultKeyRing()
                    let grantID = keyRing.tacsLeaseTokenTable.first!.vehicleAccessGrantId
                    let vehicleRef = "4321"
                    let date = Date()
                    let bleDiscoveryChange = BLEDiscoveryChangeFactory.discoveredChange(with: keyRing.sorcID(for: vehicleRef)!, date: date)

                    let expectedChange = TACSDiscoveryChangeFactory.discoveredChange(with: vehicleRef, date: date)

                    _ = sut.useAccessGrant(with: grantID, from: keyRing)
                    sut.scanInternal()
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
                    let grantID = keyRing.tacsLeaseTokenTable.first!.vehicleAccessGrantId
                    let leaseTokenFromKeyRing = keyRing.tacsLeaseTokenTable.first!.leaseToken
                    let blobFromKeyRing = keyRing.tacsSorcBlobTable.first!.blob
                    let expectedToken = try! SecureAccessBLE.LeaseToken(id: leaseTokenFromKeyRing.leaseTokenId.uuidString,
                                                                        leaseID: leaseTokenFromKeyRing.leaseId.uuidString,
                                                                        sorcID: leaseTokenFromKeyRing.sorcId,
                                                                        sorcAccessKey: leaseTokenFromKeyRing.sorcAccessKey)
                    let expectedBlob = try! SecureAccessBLE.LeaseTokenBlob(messageCounter: Int(blobFromKeyRing.blobMessageCounter)!,
                                                                           data: blobFromKeyRing.blob)

                    _ = sut.useAccessGrant(with: grantID, from: keyRing)
                    sut.connectInternal()

                    expect(sorcManager.didReceiveConnectToSorc) == 1
                    expect(sorcManager.receivedConnectToSorcLeaseToken) == expectedToken
                    expect(sorcManager.receivedConnectToSorcLeaseTokenBlob) == expectedBlob
                }
            }
            context("lease does not contain data for vehicle") {
                beforeEach {
                    sut.connectInternal()
                }
                it("dose not start connecting") {
                    expect(sorcManager.didReceiveConnectToSorc) == 0
                }
                it("notifies error via change") {
                    let expectedChange = TACSConnectionChangeFactory.leaseDataErrorChange()
                    expect(receivedConnectionChanges).to(haveCount(2))
                    expect(receivedConnectionChanges[1]) == expectedChange
                }
            }
            context("on connection change") {
                context("sorcID matches active sorcID") {
                    it("notifies change for vehicle Ref") {
                        let keyRing = TACSKeyRingFactory.validDefaultKeyRing()
                        let grantID = keyRing.tacsLeaseTokenTable.first!.vehicleAccessGrantId
                        let sorcID = keyRing.tacsSorcBlobTable.first!.blob.sorcId
                        let vehicleRef = keyRing.tacsSorcBlobTable.first!.externalVehicleRef
                        let bleConnectionChange = SecureAccessBLE.ConnectionChange(state: .connecting(sorcID: sorcID, state: .physical),
                                                                                   action: .connect(sorcID: sorcID))

                        let expectedChange = TACS.ConnectionChange(state: .connecting(vehicleRef: vehicleRef, state: .physical),
                                                                   action: .connect(vehicleRef: vehicleRef))

                        _ = sut.useAccessGrant(with: grantID, from: keyRing)
                        sut.connectInternal()
                        sorcManager.connectionChangeSubject.onNext(bleConnectionChange)

                        expect(receivedConnectionChanges).to(haveCount(2))
                        expect(receivedConnectionChanges.last!) == expectedChange
                    }
                }
                context("sorcID does not match active sorcID") {
                    it("does not notify change") {
                        let keyRing = TACSKeyRingFactory.validDefaultKeyRing()
                        let grantID = keyRing.tacsLeaseTokenTable.first!.vehicleAccessGrantId
                        _ = sut.useAccessGrant(with: grantID, from: keyRing)
                        sut.scanInternal()
                        let anotherSorcID = SorcID(uuidString: "be2fecaf-734b-4252-8312-59d477200a20")!
                        let bleConnectionChange = SecureAccessBLE.ConnectionChange(state: .connecting(sorcID: anotherSorcID, state: .physical),
                                                                                   action: .connect(sorcID: anotherSorcID))
                        sorcManager.connectionChangeSubject.onNext(bleConnectionChange)
                        expect(receivedConnectionChanges).to(haveCount(1))
                    }
                }
            }
        }
    }
}
