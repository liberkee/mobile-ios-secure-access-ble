//
//  SessionManagerType.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import CommonUtils

protocol SessionManagerType {

    var connectionChange: ChangeSubject<ConnectionChange> { get }

    func connectToSorc(leaseToken: LeaseToken, leaseTokenBlob: LeaseTokenBlob)
    func disconnect()

    var serviceGrantResultReceived: PublishSubject<ServiceGrantResult> { get }

    func requestServiceGrant(_ serviceGrantID: ServiceGrantID)
}
