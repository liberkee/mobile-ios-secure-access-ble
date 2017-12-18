//
//  UUIDTransform.swift
//  CommonUtils
//
//  Created on 16.09.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import ObjectMapper

/// Converts a string from JSON to a UUID and vice versa.
/// Assumes a lowercased UUID format when converting to JSON.
public class UUIDTransform: TransformType {
    public typealias Object = UUID
    public typealias JSON = String

    public init() {}

    public func transformFromJSON(_ value: Any?) -> UUID? {
        guard let string = value as? String else {
            return nil
        }

        return string.contains("-") ? UUID(uuidString: string)
            : string.dataFromHexadecimalString().flatMap { UUID(data: $0) }
    }

    public func transformToJSON(_ value: UUID?) -> String? {
        guard let uuid = value else {
            return nil
        }
        return uuid.uuidString.lowercased()
    }
}
