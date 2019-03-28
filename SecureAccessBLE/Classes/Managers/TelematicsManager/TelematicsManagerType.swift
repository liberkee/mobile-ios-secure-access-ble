// TelematicsManagerType.swift
// SecureAccessBLE

// Created on 26.03.19.
// Copyright © 2019 Huf Secure Mobile GmbH. All rights reserved.

import Foundation

public enum TelematicsDataType {
    case odometer, fuelLevelAbsolute, fuelLevelPercentage
}

public struct TelematicsDataChange: ChangeType {
    public let state: State

    public let action: Action

    public static func initialWithState(_ state: State) -> TelematicsDataChange {
        return TelematicsDataChange(state: state, action: .initial)
    }

    public typealias State = Array<TelematicsDataType>
}

extension TelematicsDataChange {
    public enum Action: Equatable {
        case initial
        case requestingData(types: [TelematicsDataType])
        case responseReceived(responses: [TelematicsDataResponse])
    }
}

extension TelematicsDataChange: Equatable {}

public protocol TelematicsManagerType {
    var telematicsDataChange: ChangeSignal<TelematicsDataChange> { get }
    func requestTelematicsData(_ types: [TelematicsDataType]) -> Void
}

protocol TelematicsManagerInternalType {
    var delegate: TelematicsManagerDelegate? { get set }
    func consume(change: ServiceGrantChange) -> ServiceGrantChange?
}
