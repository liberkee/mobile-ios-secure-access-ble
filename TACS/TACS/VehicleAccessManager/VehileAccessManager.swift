// VehileAccessManager.swift
// TACS

// Created on 23.04.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.

import SecureAccessBLE

class VehicleAccessManager: VehicleAccessManagerType {
    private let sorcManager: SorcManagerType
    private let vehicleAccessChangeSubject = ChangeSubject<VehicleAccessFeatureChange>(state: [])
    public var vehicleAccessChange: ChangeSignal<VehicleAccessFeatureChange>  {
        return vehicleAccessChangeSubject.asSignal()
    }
    init(sorcManager: SorcManagerType) {
        self.sorcManager = sorcManager
    }
    
    func requestFeature(_ vehicleAccessFeature: VehicleAccessFeature) {
        sorcManager.requestServiceGrant(vehicleAccessFeature.serviceGrantID())
    }
}

extension VehicleAccessManager: SorcInterceptor {
    func consume(change: ServiceGrantChange) -> ServiceGrantChange? {
        switch change.action {
        case .initial: return nil
        case let .requestServiceGrant(id: serviceGrant, accepted: accepted):
            guard let feature = VehicleAccessFeature(serviceGrantID: serviceGrant) else {
                return changeWithoutRequestedGrants(from: change)
            }
            let state: VehicleAccessFeatureChange.State = change.state.requestingServiceGrantIDs.compactMap {
                VehicleAccessFeature(serviceGrantID: $0)
            }
            let action: VehicleAccessFeatureChange.Action =
                .requestFeature(feature: feature, accepted: accepted)
            vehicleAccessChangeSubject.onNext(VehicleAccessFeatureChange(state: state, action: action))
            return nil
        case let .responseReceived(response):
            guard let feature = VehicleAccessFeature(serviceGrantID: response.serviceGrantID) else {
                return changeWithoutRequestedGrants(from: change)
            }
            // ensure we are waiting for response for this feature, otherwise don't consume
            guard vehicleAccessChangeSubject.state.contains(feature) else {
                return change
            }
            let stateWithoutReceivedFeature = vehicleAccessChangeSubject.state.filter { $0 != feature }
            if let response = VehicleAccessFeatureResponse(feature: feature, response: response) {
                let featureChange = VehicleAccessFeatureChange(state: stateWithoutReceivedFeature, action: .responseReceived(response: response))
                vehicleAccessChangeSubject.onNext(featureChange)
            }
            return nil
        case .requestFailed:
            //TODO: This happens if Session manager was not able to read the data
            // It can be considered as remoteFailed error because the data is corrupted.
            // Session manager will clear its queue and restart sending heart beat.
            // This means in this case no service grant responses are running anymore.
            // Consider clearing propagating the change with filtered state???
            return change
            
        default: return nil
        }
    }
    
    private func changeWithoutRequestedGrants(from change: ServiceGrantChange) -> ServiceGrantChange {
        return change.withoutGrantIDs(vehicleAccessChangeSubject.state.map { $0.serviceGrantID() })
    }
}

private extension ServiceGrantChange {
    func withoutGrantIDs(_ serviceGrantIDs: [ServiceGrantID]) -> ServiceGrantChange {
        let filteredIDs = state.requestingServiceGrantIDs.filter { !serviceGrantIDs.contains($0) }
        let newState = State(requestingServiceGrantIDs: filteredIDs)
        return ServiceGrantChange(state: newState, action: action)
    }
}
