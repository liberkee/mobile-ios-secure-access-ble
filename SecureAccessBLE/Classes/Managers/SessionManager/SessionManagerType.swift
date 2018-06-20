//
//  SessionManagerType.swift
//  SecureAccessBLE
//
//  Created on 31.08.17.
//  Copyright © 2018 Huf Secure Mobile GmbH. All rights reserved.
//

protocol SessionManagerType {
    var connectionChange: ChangeSubject<ConnectionChange> { get }

    func connectToSorc(leaseToken: LeaseToken, leaseTokenBlob: LeaseTokenBlob)
    func disconnect()

    var serviceGrantChange: ChangeSubject<ServiceGrantChange> { get }

    func requestServiceGrant(_ serviceGrantID: ServiceGrantID)
}
