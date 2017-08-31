//
//  SecurityManagerType.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import CommonUtils

protocol SecurityManagerType {

    var connectionChange: ChangeSubject<SecureConnectionChange> { get }

    func connectToSorc(leaseToken: LeaseToken, leaseTokenBlob: LeaseTokenBlob)
    func disconnect()

    var messageSent: PublishSubject<Result<SorcMessage>> { get }
    var messageReceived: PublishSubject<Result<SorcMessage>> { get }

    func sendMessage(_ message: SorcMessage)
}
