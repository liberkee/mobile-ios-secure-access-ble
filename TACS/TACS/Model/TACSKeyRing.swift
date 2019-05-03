// TACSKeyRing.swift
// TACS

// Created on 30.04.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.

import Foundation

public typealias VehicleRef = String

public struct ServiceGrant: Decodable {
    public struct Validators: Decodable {
        let startTime: String
        let endTime: String
    }

    let serviceGrantId: String
    let validators: Validators
}

public struct LeaseToken: Decodable {
    let leaseTokenDocumentVersion: String
    let leaseTokenId: UUID
    let leaseId: UUID
    let userId: String
    let sorcId: UUID
    let sorcAccessKey: String
    let startTime: String
    let endTime: String
    let serviceGrantList: [ServiceGrant]
}

public struct LeaseTokenBlob: Decodable {
    let sorcId: UUID
    let blob: String
    let blobMessageCounter: String
}

public struct TacsLeaseTokenTableEntry: Decodable {
    let vehicleAccessGrantId: String
    let leaseToken: LeaseToken
}

public struct TacsSorcBlobTableEntry: Decodable {
    let tenantId: String
    let externalVehicleRef: VehicleRef
    let keyholderId: String?
    let blob: LeaseTokenBlob
}

public struct TACSKeyRing: Decodable {
    let tacsLeaseTokenTableVersion: String
    let tacsLeaseTokenTable: [TacsLeaseTokenTableEntry]
    let tacsSorcBlobTableVersion: String
    let tacsSorcBlobTable: [TacsSorcBlobTableEntry]
}
