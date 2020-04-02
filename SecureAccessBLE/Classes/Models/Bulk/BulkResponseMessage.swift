//
//  BulkResponseMessage.swift
//  SecureAccessBLE
//
//  Created by Priya Khatri on 30.03.20.
//  Copyright © 2020 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

public struct BulkResponseMessage: SorcMessagePayload {
    var data: Data

    enum Error: Swift.Error {
        case unsupportedBulkProtocolVersion
        case badFormat
    }

    private let bulkTransferProtocolVersionII = 2
    private let rawUUIDbytesSize = 16
    private let protocolSize = 1
    private let dynamicLengthSize = 4 // UInt32

    let bulkID: [UInt8]
    let anchor: [UInt8]
    let revision: [UInt8]
    let message: Int

    // This is how the message is composed:
    // protocolVersion(1) + bulkID(16) + anchorSize(4) + dynamicAnchor(anchorSize) +
    // revisionSize(4) + dynamicRevision(revisionSize) + message(4)

    init(rawData: Data) throws {
        var rawBytes = rawData.bytes
        let protocolVersion = try BulkResponseMessage.readValue(from: &rawBytes, size: protocolSize)
        guard Int(protocolVersion.first!) == bulkTransferProtocolVersionII else {
            throw Error.unsupportedBulkProtocolVersion
        }

        data = rawData
        bulkID = try BulkResponseMessage.readValue(from: &rawBytes, size: rawUUIDbytesSize)
        anchor = try BulkResponseMessage.readDynamicValue(from: &rawBytes)
        revision = try BulkResponseMessage.readDynamicValue(from: &rawBytes)
        message = Int(try rawBytes.readLittleEndianInt32())
    }

    /// Reads a UInt32 value describing size of the actual value. After that reads the actual value. The bytes array will be reduced by the values read by this function
    /// - Parameter bytes: bytes array passed by reference, read values will be removed
    /// - Throws: `Error.badFormat` if bytes size doesn't fulfill the requirement
    /// - Returns: value
    private static func readDynamicValue(from bytes: inout [UInt8]) throws -> [UInt8] {
        let size = try bytes.readLittleEndianInt32()
        let valueSize = Int(size)
        bytes.removeFirst(MemoryLayout<UInt32>.size)
        return try readValue(from: &bytes, size: valueSize)
    }

    /// Read a value of specified size from array.
    /// - Parameters:
    ///   - bytes: bytes array passed by reference, read values will be removed
    ///   - size: size of value that should be read
    /// - Throws: `Error.badFormat` if bytes size doesn't fulfill the requirement
    /// - Returns: value
    private static func readValue(from bytes: inout [UInt8], size: Int) throws -> [UInt8] {
        guard size <= bytes.count else {
            throw Error.badFormat
        }
        let result = Array(bytes.prefix(size))
        bytes.removeFirst(size)
        return result
    }
}

private extension Array where Element == UInt8 {
    func readLittleEndianInt32() throws -> UInt32 {
        let int32Size = MemoryLayout<UInt32>.size // 4 bytes
        guard count >= int32Size else {
            throw BulkResponseMessage.Error.badFormat
        }
        return prefix(int32Size).withUnsafeBytes {
            UInt32(littleEndian: $0.load(as: UInt32.self))
        }
    }
}
