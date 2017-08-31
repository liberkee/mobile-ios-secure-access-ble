//
//  TransportManagerType.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import CommonUtils

protocol TransportManagerType {

    var connectionChange: ChangeSubject<TransportConnectionChange> { get }

    func connectToSorc(_ sorcID: SorcID)
    func disconnect()

    var dataSent: PublishSubject<Result<Data>> { get }
    var dataReceived: PublishSubject<Result<Data>> { get }

    func sendData(_ data: Data)
}

// TODO: PLAM-959

// struct SendingDataChange: ChangeType {
//    let state:
//
//    enum State {
//        case inactive
//        case sending
//    }
//
//    enum Action {
//        case sendData(Data)
//        case
//    }
// }
//
// struct ReceivingDataChange: ChangeType {
//
// }
