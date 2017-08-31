//
//  ServiceGrantResult.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

public typealias ServiceGrantID = UInt16

public enum ServiceGrantResult: Equatable {

    case success(ServiceGrantResponse)
    case failure(Error)

    public static func ==(lhs: ServiceGrantResult, rhs: ServiceGrantResult) -> Bool {
        switch (lhs, rhs) {
        case let (.success(lResponse), .success(rResponse)):
            return lResponse == rResponse
        case let (.failure(lError), .failure(rError)):
            return lError == rError
        default:
            return false
        }
    }

    public enum Error: Swift.Error, CustomStringConvertible {

        case receivedInvalidData
        case queueIsFull

        public var description: String {
            switch self {
            case .receivedInvalidData:
                return "Invalid data was received."
            case .queueIsFull:
                return "Queue is full."
            }
        }
    }
}

public struct ServiceGrantResponse: Equatable {

    public enum Status: UInt8 {
        case success = 0x00
        case pending = 0x01
        case failure = 0x02
        case notAllowed = 0x03
    }

    let sorcID: SorcID
    let serviceGrantID: ServiceGrantID
    let status: Status
    let responseData: String

    public static func ==(lhs: ServiceGrantResponse, rhs: ServiceGrantResponse) -> Bool {
        return lhs.sorcID == rhs.sorcID
            && lhs.serviceGrantID == rhs.serviceGrantID
            && lhs.status == rhs.status
            && lhs.responseData == rhs.responseData
    }
}
