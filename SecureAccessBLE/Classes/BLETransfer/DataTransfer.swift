//
//  DataTransfer.swift
//  TransportTest
//
//  Created by Sebastian Stüssel on 21.08.15.
//  Copyright (c) 2016 Huf Secure Mobile. All rights reserved.
//

import Foundation

/**
 The Delegate for a DataTransfer object
 */
protocol DataTransferDelegate: class {

    /**
     Tells the delegate that data was send.

     - parameter dataTransferObject: The DataTransfer object.
     - parameter data: The data which was send.
     */
    func transferDidSendData(_ dataTransferObject: DataTransfer, data: Data)

    /**
     Tells the delegate that data was received.

     - parameter dataTransferObject: The DataTransfer object.
     - parameter data: The data which was received.
     */
    func transferDidReceivedData(_ dataTransferObject: DataTransfer, data: Data)
}

/**
 Objects that confirm to DataTransfer must be able to send data
 and must have a delegate confirming to DataTransferDelegate
 */
protocol DataTransfer {

    /// A delegate conforming to DataTransferDelegate
    weak var delegate: DataTransferDelegate? { get set }

    /**
     A method to send data.

     - parameter data: The data package which should be send.
     */
    func sendData(_ data: Data)
}
