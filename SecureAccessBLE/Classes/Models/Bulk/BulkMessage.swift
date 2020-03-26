//
//  BulkMessage.swift
//  SecureAccessBLE
//
//  Created on 26.03.20.
//  Copyright © 2020 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

enum BulkMessageID: UInt8 {
    
    case unknownBulk = -1
    //    UNKNOWN_BULK_RESPONSE_CODE(-1),
    case anchorUnmatchConfig = 0x64
    
    case signatureMismatchConfig = 0x65
    
    case firmwareMismatchConfig = 0x66
    
    case oldRevisionConfig = 0x67
    
    case metadataBulkError = 0x68
    
    case oldRevisionApply = 0x69
    
    case achorUnmatchApply = 0x6A
    
    case strategyUnknownApply = 0x6B
    
    case signatureMismatchApply = 0x6C
    
    case contentsInvalidConfig = 0x6D
    
    case contentsInvalidApply =  0x6E
    
    case downloadedConfig = 0x78
    
    case successApply = 0x79
    
    case failureApply = 0x7A
    
    case discardedConfig = 0x7D
    
    case discardedApply = 0x7E
    
    case collectedConfig = 0x7F
    
    case collectingConfigsApply = 0x82
    
    case waitingApplicationApply = 0x83
    
    case applicationApplySuccess = 0x84
    
    case applicationApplyFailed = 0x86
    
    case registryUpdateApplySuccess = 0x87
    
    case registryUpdateApplyFailed = 0x88
    
    case bleTranferConfigError = 0x89
    
    case bleVersionMismatchConfig = 0x8A
    
    case alreadyInStorageConfig = 0x8B
    
    case alreadyInStorageApply = 0x8C
}
