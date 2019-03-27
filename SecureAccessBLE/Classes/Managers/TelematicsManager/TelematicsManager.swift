// TelematicsManager.swift
// SecureAccessBLE

// Created on 26.03.19.
// Copyright © 2019 Huf Secure Mobile GmbH. All rights reserved.

import Foundation

public class TelematicsManager: TelematicsManagerType {
    private let telematicsDataChangeSubject: ChangeSubject<TelematicsDataChange> = ChangeSubject<TelematicsDataChange>(state: [])
    public var telematicsDataChange: ChangeSignal<TelematicsDataChange> {
        return telematicsDataChangeSubject.asSignal()
    }

    internal static let telematicsServiceGrantID: UInt16 = 9
    public func requestTelematicsData(_ types: [TelematicsDataType]) {
        // this should not happen unrespectedly of the fact if a request can be processed at all
        let change = TelematicsDataChange(state: types, action: .requestingData(types: types))
        telematicsDataChangeSubject.onNext(change)
    }

    init() {}

    private func onResponseReceived(_ response: ServiceGrantResponse) {
        switch response.status {
        case .success:
            guard let tripMetaData = try? TripMetaData(responseData: response.responseData) else {
                // report error
                return
            }
            var telematicsResponses = [TelematicsDataResponse]()
            for requestedType in telematicsDataChangeSubject.state {
                let telematicsDataResponse = TelematicsDataResponse(tripMetaData: tripMetaData, requestedType: requestedType)
                telematicsResponses.append(telematicsDataResponse)
            }
            let change = TelematicsDataChange(state: [], action: .responseReceived(responses: telematicsResponses))
            telematicsDataChangeSubject.onNext(change)
        default:
            break
        }
    }
}

extension TelematicsManager: TelematicsManagerInternalType {
    internal func consume(change: ServiceGrantChange) -> ServiceGrantChange? {
        switch change.action {
        case .initial: return change.changeWithoutTelematicsID()
        case let .requestServiceGrant(id: serviceGrantId, accepted: _):
            return serviceGrantId == TelematicsManager.telematicsServiceGrantID ? nil : change.changeWithoutTelematicsID()
        case let .responseReceived(response):
            onResponseReceived(response)
            return response.serviceGrantID == TelematicsManager.telematicsServiceGrantID ? nil : change.changeWithoutTelematicsID()
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
