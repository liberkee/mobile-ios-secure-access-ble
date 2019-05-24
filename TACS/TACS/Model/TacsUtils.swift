// TacsUtils.swift
// TACS

// Created on 23.05.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.

import Foundation

public extension TACSKeyRing {
    // swiftlint:disable:next function_parameter_count
    static func craftKeyring(leaseTokenId: UUID,
                             leaseId: UUID,
                             sorcId: UUID,
                             sorcAccessKey: String,
                             blob: String,
                             blobMessageCounter: String,
                             externalVehicleRef: String,
                             vehicleAccessGrantId: String,
                             keyholderId: UUID?) -> TACSKeyRing {
        let tacsLeaseTokenBlob = TACS.LeaseTokenBlob(sorcId: sorcId,
                                                     blob: blob,
                                                     blobMessageCounter: blobMessageCounter)

        let tacsSorcBlobTableEntry = TacsSorcBlobTableEntry(tenantId: "",
                                                            externalVehicleRef: externalVehicleRef,
                                                            keyholderId: keyholderId,
                                                            blob: tacsLeaseTokenBlob)

        let validators = ServiceGrant.Validators(startTime: "", endTime: "")
        let serviceGrant = ServiceGrant(serviceGrantId: "0", validators: validators)

        let leaseToken = LeaseToken(leaseTokenDocumentVersion: "0",
                                    leaseTokenId: leaseTokenId,
                                    leaseId: leaseId,
                                    userId: "0",
                                    sorcId: sorcId,
                                    sorcAccessKey: sorcAccessKey,
                                    startTime: "",
                                    endTime: "",
                                    serviceGrantList: [serviceGrant])

        let tacsLeaseTokenTableEntry = TacsLeaseTokenTableEntry(vehicleAccessGrantId: vehicleAccessGrantId,
                                                                leaseToken: leaseToken)

        let keyring = TACSKeyRing(tacsLeaseTokenTableVersion: "0",
                                  tacsLeaseTokenTable: [tacsLeaseTokenTableEntry],
                                  tacsSorcBlobTableVersion: "0",
                                  tacsSorcBlobTable: [tacsSorcBlobTableEntry])
        return keyring
    }
}
