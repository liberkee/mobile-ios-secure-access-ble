// VehicleAccessFeatureResponse.swift
// TACS

// Created on 25.04.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.

import SecureAccessBLE

public enum VehicleAccessFeatureResponse: Equatable {
    case success(status: VehicleAccessFeatureStatus)
    case failure(feature: VehicleAccessFeature, error: VehicleAccessFeatureError)
    internal init?(feature: VehicleAccessFeature, response: ServiceGrantResponse) {
        switch response.status {
        case .invalidTimeFrame:
            self = .failure(feature: feature, error: .denied)
        case .failure, .notAllowed:
            self = .failure(feature: feature, error: .remoteFailed)
        case .success:
            if let featureStatus = VehicleAccessFeatureStatus(feature: feature, serviceGrantResponseData: response.responseData) {
                self = .success(status: featureStatus)
            } else {
                self = .failure(feature: feature, error: .remoteFailed)
            }
        case .pending:
            return nil
        }
    }
}

public enum VehicleAccessFeatureStatus: Equatable {
    case lock
    case unlock
    case enableIgnition
    case disableIgnition
    case lockStatus(locked: Bool)
    case ignitionStatus(enabled: Bool)

    // swiftlint:disable:next cyclomatic_complexity
    init?(feature: VehicleAccessFeature, serviceGrantResponseData: String) {
        switch feature {
        case .lock:
            self = .lock
        case .unlock:
            self = .unlock
        case .enableIgnition:
            self = .enableIgnition
        case .disableIgnition:
            self = .disableIgnition
        case .lockStatus:
            let featureResult = FeatureResult(responseData: serviceGrantResponseData)
            switch featureResult {
            case .locked:
                self = .lockStatus(locked: true)
            case .unlocked:
                self = .lockStatus(locked: false)
            default:
                return nil
            }
        case .ignitionStatus:
            let featureResult = FeatureResult(responseData: serviceGrantResponseData)
            switch featureResult {
            case .enabled:
                self = .ignitionStatus(enabled: true)
            case .disabled:
                self = .ignitionStatus(enabled: false)
            default:
                return nil
            }
        }
    }
}

public enum VehicleAccessFeatureError {
    /// Query failed, because the vehicle is not connected
    case notConnected
    /// Query failed, because the lease does not permit access to telematics data
    case denied
    /// Query failed, because the remote CAM encountered an internal error
    case remoteFailed
}

private enum FeatureResult: String {
    // door was locked
    case locked = "LOCKED"
    // door was unlocked
    case unlocked = "UNLOCKED"
    // ignition enabled
    case enabled = "ENABLED"
    // ignition disabled
    case disabled = "DISABLED"
    // unknown result
    case unknown = "UNKNOWN"

    init(responseData: String) {
        guard !responseData.isEmpty, let result = FeatureResult(rawValue: responseData) else {
            self = .unknown
            return
        }
        self = result
    }
}
