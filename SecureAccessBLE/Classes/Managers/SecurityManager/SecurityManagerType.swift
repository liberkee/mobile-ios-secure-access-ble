//
//  SecurityManagerType.swift
//  SecureAccessBLE
//
//  Created on 31.08.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

protocol SecurityManagerType {
    var connectionChange: ChangeSubject<SecureConnectionChange> { get }

    func connectToSorc(leaseToken: LeaseToken, leaseTokenBlob: LeaseTokenBlob)
    func disconnect()

    var messageSent: PublishSubject<Result<SorcMessage>> { get }
    var messageReceived: PublishSubject<Result<SorcMessage>> { get }

    func sendMessage(_ message: SorcMessage)
}
