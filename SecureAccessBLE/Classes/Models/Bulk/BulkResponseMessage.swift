//
//  BulkResponseMessage.swift
//  SecureAccessBLE
//
//  Created by Priya Khatri on 30.03.20.
//  Copyright © 2020 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

struct BulkResponseMessage: SorcMessagePayload {
    var data: Data

    enum Error: Swift.Error {
        case unsupportedBulkProtocolVersion
        case unsupportedAnchor
        case unsupportedRevision
    }

    private let bulkTransferProtocolVersionII = 2
    private let rawUUIDbytesSize = 16

    let bulkID: [UInt8]
    let anchor: [UInt8]
    let revision: [UInt8]
    let message: Int

    init(rawData: Data) throws {
        let protocolVersion = rawData.subdata(in: 0 ..< 1).uint8

        guard protocolVersion == bulkTransferProtocolVersionII else {
            throw Error.unsupportedBulkProtocolVersion
        }
        data = rawData

        // protocolVersion(1) + idLength(1) + versionLength(1) + bulkIdLength(16) = total(19)
        bulkID = rawData.subdata(in: 3 ..< 19).bytes

        // anchor
        var anchorLength = 4

        let _dynAnchorLen: UInt32? = rawData.subdata(in: 19 ..< (19 + anchorLength)).withUnsafeBytes { UInt32(littleEndian: $0.load(as: UInt32.self)) }
        let dynAnchorLen = Int(_dynAnchorLen!)

        guard dynAnchorLen < rawData.bytes.count else {
            throw Error.unsupportedAnchor
        }

        anchor = rawData.subdata(in: (19 + anchorLength) ..< (19 + anchorLength + dynAnchorLen)).bytes

        anchorLength = anchorLength + dynAnchorLen

        // revision
        var revisionLength = 4
        let _dynRevisionLen: UInt32 = rawData.subdata(in: (19 + anchorLength) ..< (19 + anchorLength + revisionLength)).withUnsafeBytes { UInt32(littleEndian: $0.load(as: UInt32.self)) }

        let dynRevisionLen = Int(_dynRevisionLen)

        guard dynRevisionLen < rawData.bytes.count else {
            throw Error.unsupportedRevision
        }

        revision = rawData.subdata(in: (19 + anchorLength + revisionLength) ..< (19 + anchorLength + revisionLength + dynRevisionLen)).bytes

        revisionLength = revisionLength + dynRevisionLen

        // message
        let messageLength: UInt32 = rawData.subdata(in: (19 + anchorLength + revisionLength) ..< rawData.bytes.count).withUnsafeBytes { UInt32(littleEndian: $0.load(as: UInt32.self)) }

        message = Int(messageLength)
    }
}
