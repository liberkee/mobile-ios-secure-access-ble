// TelematicsManager.swift
// SecureAccessBLE

// Created on 26.03.19.
// Copyright © 2019 Huf Secure Mobile GmbH. All rights reserved.

import Foundation

// Delegate type for internal communication
protocol TelematicsManagerDelegate: class {
    func requestTelematicsData() -> SorcManager.TelematicsRequestResult
}

/// Telematics manager which can be used to retrieve telematics data from the vehicle
public class TelematicsManager: TelematicsManagerType {
    private let telematicsDataChangeSubject: ChangeSubject<TelematicsDataChange> = ChangeSubject<TelematicsDataChange>(state: [])
    internal static let telematicsServiceGrantID: UInt16 = 9

    /// Telematics data change signal which can be used to retrieve data changes
    public var telematicsDataChange: ChangeSignal<TelematicsDataChange> {
        return telematicsDataChangeSubject.asSignal()
    }

    /// Requests telematics data from the vehicle
    ///
    /// - Parameter types: Data types which need to be retrieved
    public func requestTelematicsData(_ types: [TelematicsDataType]) {
        guard let delegate = self.delegate else { fatalError("delegate not set") }
        if telematicsDataChangeSubject.state.count != 0 {
            // In this state, request is already running, so we only notify requesting state with added types
            let combinedTypes = Array(Set(types + telematicsDataChangeSubject.state))
            notifyRequestingChange(with: combinedTypes)
            return
        }
        let requestStatus = delegate.requestTelematicsData()
        switch requestStatus {
        case .success:
            notifyRequestingChange(with: types)
        case .notConnected:
            notifyNotConnectedChange(with: types)
        }
    }

    weak var delegate: TelematicsManagerDelegate?

    init() {}

    private func onResponseReceived(_ response: ServiceGrantResponse) {
        switch response.status {
        case .success:
            guard let tripMetaData = try? TripMetaData(responseData: response.responseData) else {
                notifyRemoteFailedChange()
                return
            }
            notifyResponseReceived(with: tripMetaData)
        case .invalidTimeFrame, .notAllowed:
            notifyRequestDeniedChange()
        case .pending: break
        case .failure:
            notifyRemoteFailedChange()
        }
    }

    private func notifyRequestingChange(with types: [TelematicsDataType]) {
        let change = TelematicsDataChange(state: types, action: .requestingData(types: types))
        telematicsDataChangeSubject.onNext(change)
    }

    private func notifyNotConnectedChange(with types: [TelematicsDataType]) {
        let responses = types.map { TelematicsDataResponse.error($0, .notConnected) }
        let action = TelematicsDataChange.Action.responseReceived(responses: responses)
        let change = TelematicsDataChange(state: [], action: action)
        telematicsDataChangeSubject.onNext(change)
    }

    private func notifyRemoteFailedChange() {
        let telematicsResponses = telematicsDataChangeSubject.state.map {
            TelematicsDataResponse.error($0, .remoteFailed)
        }
        let change = TelematicsDataChange(state: [], action: .responseReceived(responses: telematicsResponses))
        telematicsDataChangeSubject.onNext(change)
    }

    private func notifyResponseReceived(with tripMetaData: TripMetaData) {
        let telematicsResponses = telematicsDataChangeSubject.state.map {
            TelematicsDataResponse(tripMetaData: tripMetaData, requestedType: $0)
        }
        let change = TelematicsDataChange(state: [], action: .responseReceived(responses: telematicsResponses))
        telematicsDataChangeSubject.onNext(change)
    }

    private func notifyRequestDeniedChange() {
        let telematicsResponses = telematicsDataChangeSubject.state.map {
            TelematicsDataResponse.error($0, .denied)
        }
        let change = TelematicsDataChange(state: [], action: .responseReceived(responses: telematicsResponses))
        telematicsDataChangeSubject.onNext(change)
    }
}

extension TelematicsManager: TelematicsManagerInternalType {
    internal func consume(change: ServiceGrantChange) -> ServiceGrantChange? {
        switch change.action {
        case .initial: return change.changeWithoutTelematicsID()
        case let .requestServiceGrant(id: serviceGrantId, accepted: _):
            return serviceGrantId == TelematicsManager.telematicsServiceGrantID ? nil : change.changeWithoutTelematicsID()
        case let .responseReceived(response):
            if response.serviceGrantID == TelematicsManager.telematicsServiceGrantID {
                onResponseReceived(response)
                return nil
            } else {
                return change.changeWithoutTelematicsID()
            }
        case .requestFailed, .reset:
            return change.changeWithoutTelematicsID()
        }
    }
}

private extension ServiceGrantChange {
    func changeWithoutTelematicsID() -> ServiceGrantChange {
        if !state.requestingServiceGrantIDs.contains(TelematicsManager.telematicsServiceGrantID) {
            return self
        } else {
            let filteredIDs = state.requestingServiceGrantIDs.filter { $0 != TelematicsManager.telematicsServiceGrantID }
            let newState = State(requestingServiceGrantIDs: filteredIDs)
            return ServiceGrantChange(state: newState, action: action)
        }
    }
}
