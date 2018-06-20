//
//  TransportManagerType.swift
//  SecureAccessBLE
//
//  Created on 31.08.17.
//  Copyright © 2018 Huf Secure Mobile GmbH. All rights reserved.
//

protocol TransportManagerType {
    var connectionChange: ChangeSubject<TransportConnectionChange> { get }

    func connectToSorc(_ sorcID: SorcID)
    func disconnect()

    var dataSent: PublishSubject<Result<Data>> { get }
    var dataReceived: PublishSubject<Result<Data>> { get }

    func sendData(_ data: Data)
}
