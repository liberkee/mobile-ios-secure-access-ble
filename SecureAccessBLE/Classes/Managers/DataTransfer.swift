//
//  DataTransfer.swift
//  SecureAccessBLE
//
//  Copyright (c) 2016 Huf Secure Mobile. All rights reserved.
//

import Foundation
import CommonUtils

/// A protocol for sending and receiving data
protocol DataTransfer {

    var sentData: PublishSubject<Error?> { get }
    var receivedData: PublishSubject<Result<Data>> { get }

    func sendData(_ data: Data)
}
