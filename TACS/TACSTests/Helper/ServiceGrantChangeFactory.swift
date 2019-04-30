// ServiceGrantChangeFactory.swift
// TACSTests

// Created on 26.04.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.

@testable import SecureAccessBLE
@testable import TACS

class ServiceGrantChangeFactory {
    static func acceptedRequestChange(feature: VehicleAccessFeature) -> ServiceGrantChange {
        let state = ServiceGrantChange.State(requestingServiceGrantIDs: [])
        let action = ServiceGrantChange.Action.requestServiceGrant(id: feature.serviceGrantID(), accepted: true)
        let serviceGrantChange = ServiceGrantChange(state: state, action: action)
        return serviceGrantChange
    }

    static func responseReceivedChange(feature: VehicleAccessFeature) -> ServiceGrantChange {
        let state = ServiceGrantChange.State(requestingServiceGrantIDs: [])
        let response = ServiceGrantResponse(sorcID: VehicleAccessManagerTests.sorcID,
                                            serviceGrantID: feature.serviceGrantID(),
                                            status: ServiceGrantResponse.Status.success,
                                            responseData: "")
        let action = ServiceGrantChange.Action.responseReceived(response)
        let change = ServiceGrantChange(state: state, action: action)
        return change
    }

    static func acceptedTelematicsRequestChange() -> ServiceGrantChange {
        let state = ServiceGrantChange.State(requestingServiceGrantIDs: [])
        let action = ServiceGrantChange.Action.requestServiceGrant(id: TelematicsManager.telematicsServiceGrantID, accepted: true)
        return ServiceGrantChange(state: state, action: action)
    }
}
