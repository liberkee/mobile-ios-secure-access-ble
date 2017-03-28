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
    
    /**
     Tells the delegate that a connection was established.
    
     - parameter dataTransferObject: The DataTransfer object.
     - parameter data: The data which was received.
    */
    func transferDidChangedConnectionState(_ dataTransferObject: DataTransfer, isConnected: Bool)
    
    /**
     Tells the delegate that a SID was discovered.
    
     - parameter dataTransferObject: The DataTransfer object.
     - parameter sidId: The id of the discovered SID.
    */
    func transferDidDiscoveredSidId(_ dataTransferObject: DataTransfer, newSid: SID)
    
    /**
     Tells the delegate that a SID was vanished.
    
     - parameter dataTransferObject: The DataTransfer object.
     - parameter sidId: The id of the discovered SID.
    */
    //func transferDidLostSidId(dataTransferObject: DataTransfer, oldSids: [SID])
    
    /**
     In transporter runs a timer, it reports wenn all saved SIDs must be filtered
     
     - parameter dataTransferObject: Scanner instance
     */
    func transferShouldFilterOldIds(_ dataTransferObject: DataTransfer)
    
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
    
    ///A delegate confirming to DataTransferDelegate
    weak var delegate: DataTransferDelegate? {get set}
    
    ///The connection state
    var isConnected: Bool {get}
    /**
     A method to send data.
    
     - parameter data: The data package which should be send.
    */
    func sendData(_ data: Data)
    
    /**
     A method to connecting to a specified sid.
    
     - parameter data: The sid id.
    */
    func connectToSidWithId(_ sidId: String)
    
    ///Disconnect the current connected sid.
    func disconnect()
}

