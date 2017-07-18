//
//  DataTransfer.swift
//  TransportTest
//
//  Created by Sebastian Stüssel on 21.08.15.
//  Copyright (c) 2016 Huf Secure Mobile. All rights reserved.
//

import Foundation

enum TransferConnectionState {
    case disconnected
    case connecting(sorc: SID)
    case connected(sorc: SID)
}

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

    /**
     Tells the delegate that a connection was established.

     - parameter dataTransferObject: The DataTransfer object.
     - parameter state: The state of the transfer connection.
     */
    func transferDidChangedConnectionState(_ dataTransferObject: DataTransfer, state: TransferConnectionState)

    /**
     Tells the delegate that a SID was discovered.

     - parameter dataTransferObject: The DataTransfer object.
     - parameter sidId: The id of the discovered SID.
     */
    func transferDidDiscoveredSidId(_ dataTransferObject: DataTransfer, newSid: SID)

    /**
     Transporter reports if that was successfully connected with a SID

     - parameter dataTransferObject: transporter instance
     - parameter sid:                connected SID instance
     */
    func transferDidConnectSid(_ dataTransferObject: DataTransfer, sid: SID)

    /**
     Tells the delegate if a connection attempt failed

     - parameter dataTransferObject: Transporter instance
     - parameter sid: The SID the connection should have made to
     - parameter error: Describes the error
     */
    func transferDidFailToConnectSid(_ dataTransferObject: DataTransfer, sid: SID, error: Error?)
}

/**
 Objects that confirm to DataTransfer must be able to send data
 and must have a delegate confirming to DataTransferDelegate
 */
protocol DataTransfer {

    /// A delegate conforming to DataTransferDelegate
    weak var delegate: DataTransferDelegate? { get set }

    /// The connection state of the data transfer
    var connectionState: TransferConnectionState { get }

    /**
     A method to send data.

     - parameter data: The data package which should be send.
     */
    func sendData(_ data: Data)

    /**
     A method to connecting to a specified SORC.

     - parameter sorc: The SORC.
     */
    func connectToSorc(_ sorc: SID)

    /// Disconnect the current connected sid.
    func disconnect()
}
