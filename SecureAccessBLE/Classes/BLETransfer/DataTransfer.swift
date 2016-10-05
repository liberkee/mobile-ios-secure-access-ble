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
    func transferDidSendData(dataTransferObject: DataTransfer, data: NSData)
    
    /**
     Tells the delegate that data was received.
    
     - parameter dataTransferObject: The DataTransfer object.
     - parameter data: The data which was received.
    */
    func transferDidReceivedData(dataTransferObject: DataTransfer, data: NSData)
    
    /**
     Tells the delegate that a connection was established.
    
     - parameter dataTransferObject: The DataTransfer object.
     - parameter data: The data which was received.
    */
    func transferDidChangedConnectionState(dataTransferObject: DataTransfer, isConnected: Bool)
    
    /**
     Tells the delegate that a SID was discovered.
    
     - parameter dataTransferObject: The DataTransfer object.
     - parameter sidId: The id of the discovered SID.
    */
    func transferDidDiscoveredSidId(dataTransferObject: DataTransfer, newSid: SID)
    
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
    func transferShouldFilterOldIds(dataTransferObject: DataTransfer)
    
    /**
     Transporter reports if that was successfully connected with a SID
     
     - parameter dataTransferObject: transporter instance
     - parameter sid:                connected SID instance
     */
    func transferDidconnectedSid(dataTransferObject: DataTransfer, sid: SID)
    
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
    func sendData(data: NSData)
    
    /**
     A method to connecting to a specified sid.
    
     - parameter data: The sid id.
    */
    func connectToSidWithId(sidId: String)
    
    ///Disconnect the current connected sid.
    func disconnect()
}

