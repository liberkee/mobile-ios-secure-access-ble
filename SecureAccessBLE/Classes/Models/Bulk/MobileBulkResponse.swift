//
//  MobileBulkResponse.swift
//  SecureAccessBLE
//
//  Created on 26.03.20.
//  Copyright © 2020 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

public enum BulkMessageID: Int {
    case unknownBulk = -1
    case anchorUnmatchConfig = 100
    case signatureMismatchConfig = 101
    case firmwareMismatchConfig = 102
    case oldRevisionConfig = 103
    case metadataBulkError = 104
    case oldRevisionApply = 105
    case achorUnmatchApply = 106
    case strategyUnknownApply = 107
    case signatureMismatchApply = 108
    case contentsInvalidConfig = 109
    case contentsInvalidApply = 110
    case downloadedConfig = 120
    case successApply = 121
    case failureApply = 122
    case discardedConfig = 125
    case discardedApply = 126
    case collectedConfig = 127
    case collectingConfigsApply = 130
    case waitingApplicationApply = 131
    case applicationApplySuccess = 132
    case applicationApplyFailed = 134
    case registryUpdateApplySuccess = 135
    case registryUpdateApplyFailed = 136
    case bleTranferConfigError = 137
    case bleVersionMismatchConfig = 138
    case alreadyInStorageConfig = 139
    case alreadyInStorageApply = 140
}

public struct MobileBulkResponse: Equatable {
    public let bulkID: UUID
    public let anchor: String
    public let revision: String
    public let message: BulkMessageID

    enum Error: Swift.Error {
        case badBulkIDFormat
        case badAnchorFormat
        case badRevisionFormat
        case badMessageFormat
    }

    init(bulkResponseMessage: BulkResponseMessage) throws {
        guard let bulkID = UUID(data: Data(bulkResponseMessage.bulkID)) else { throw Error.badBulkIDFormat }
        self.bulkID = bulkID

        guard let anchor = String(bytes: bulkResponseMessage.anchor, encoding: .ascii) else { throw Error.badAnchorFormat }
        self.anchor = anchor

        guard let revision = String(bytes: bulkResponseMessage.revision, encoding: .ascii) else { throw Error.badRevisionFormat }
        self.revision = revision

        guard let messageValue = BulkMessageID(rawValue: bulkResponseMessage.message) else { throw
            Error.badMessageFormat
        }
        message = messageValue
    }
}
