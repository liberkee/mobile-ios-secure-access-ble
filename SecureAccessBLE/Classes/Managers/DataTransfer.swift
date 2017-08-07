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

    var sentData: PublishSubject<()> { get }
    var receivedData: PublishSubject<Data> { get }

    func sendData(_ data: Data)
}
