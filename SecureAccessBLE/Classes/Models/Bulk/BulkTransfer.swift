//
//  BulkTransfer.swift
//  SecureAccessBLE
//
//  Created on 27.03.20.
//  Copyright © 2020 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

struct BulkTransfer: SorcMessagePayload {
 
    //TODO: What to do?
    var message: BulkTransmitMessage {
        return BulkTransmitMessage()
    }
    
    init() {
        
    }
}
