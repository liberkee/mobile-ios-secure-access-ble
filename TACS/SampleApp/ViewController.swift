// ViewController.swift
//

// Created on 06.06.18.
// Copyright © 2018 Huf Secure Mobile. All rights reserved.


import UIKit
import TACS
import SecureAccessBLE

class TACSKeyRingProvider {
    static func keyRing() -> TACSKeyRing {
        let url = Bundle.main.url(forResource: "mock_keyring", withExtension: "json")!
        let json = try! String(contentsOf: url).data(using: .utf8)!
        return try! JSONDecoder().decode(TACSKeyRing.self, from: json)
    }
}

class ViewController: UIViewController {
    var tacsManager: TACSManager!
    let disposeBag = DisposeBag()
    
    let keyRing = TACSKeyRingProvider.keyRing()
    var vehicleAccessGrantId: String = "MySampleAccessGrantId"
    
    @IBOutlet weak var vehicleStatusOutputView: UITextView!
    @IBOutlet weak var telematicsOutputView: UITextView!
    @IBOutlet weak var keyholderStatusOutputView: UITextView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let queue = DispatchQueue(label: "com.queue.blehandling")
        tacsManager = TACSManager(queue: queue)
        
        // Subscribe to bluetooth status signal
        tacsManager.isBluetoothEnabled.subscribe { [weak self] bluetoothOn in
            self?.onBluetoothStatusChange(bluetoothOn)
        }
        .disposed(by: disposeBag)
        
        // Subscribe to discovery change signal
        tacsManager.discoveryChange.subscribe { [weak self] discoveryChange in
            // handle discovery state changes
            self?.onDiscoveryChange(discoveryChange)
            }
            .disposed(by: disposeBag) // add disposable to a disposeBag which will take care about removing subscriptions on deinit
        
        // Subscribe to connection change signal
        tacsManager.connectionChange.subscribe { [weak self] connectionChange in
            self?.onConnectionChange(connectionChange)
            }
            .disposed(by: disposeBag)
        
        // Subscribe to vehicle access change signal
        tacsManager.vehicleAccessManager.vehicleAccessChange.subscribe { [weak self] vehicleAccessChange in
            // Handle vehicle access changes
            self?.onVehicleAccessFeatureChange(vehicleAccessChange)
            }
            .disposed(by: disposeBag)
        
        
        // Subscribe to telematics data change signal
        tacsManager.telematicsManager.telematicsDataChange.subscribe { [weak self] telematicsDataChange in
            self?.onTelematicsDataChange(telematicsDataChange)
            }
            .disposed(by: disposeBag)
        
        //Subscribe to keyholder state change signal
        tacsManager.keyholderManager.keyholderChange.subscribe { [weak self] change  in
            self?.onKeyholderStatusChange(change)
        }
        .disposed(by: disposeBag)
        
        // Prepare tacsmanager with vehicleAccessGrantId and appropriate keyring
        let useAccessGrantResult = tacsManager.useAccessGrant(with: vehicleAccessGrantId, from: keyRing)
        assert(useAccessGrantResult)
    }
    
    @IBAction func connect(_ sender: Any) {
        if case .connected = tacsManager.connectionChange.state { return }
        // Start scanning for vehicles
        tacsManager.startScanning()
    }
    
    @IBAction func lockDoors(_ sender: Any) {
        tacsManager.vehicleAccessManager.requestFeature(.lock)
        tacsManager.vehicleAccessManager.requestFeature(.lockStatus)
    }
    
    @IBAction func unlockDoors(_ sender: Any) {
        tacsManager.vehicleAccessManager.requestFeature(.unlock)
        tacsManager.vehicleAccessManager.requestFeature(.lockStatus)
    }
    
    @IBAction func getTelematicsData(_ sender: Any) {
        tacsManager.telematicsManager.requestTelematicsData([.odometer, .fuelLevelAbsolute, .fuelLevelPercentage])
    }
    
    @IBAction func requestKeyholderStatus(_ sender: Any) {
        tacsManager.keyholderManager.requestStatus(timeout: 10.0)
    }
    
    private func onBluetoothStatusChange(_ bluetoothOn: Bool) {
        // Reflect on ble device change by providing necessary feedback to the user.
        // Running discoveries for vehicle or keyholder will automatically stop and notified via signals.
        DispatchQueue.main.async { [weak self] in
            let stateString = bluetoothOn ? "on" : "off"
            self?.vehicleStatusOutputView.insertText("\nBluetooth state \(stateString)")
        }
    }
    
    private func onDiscoveryChange(_ discoveryChange: TACS.DiscoveryChange) {
        let action = discoveryChange.action
        let actionDescription = String(describing: action)
        if !actionDescription.isEmpty {
            DispatchQueue.main.async { [weak self] in
                self?.vehicleStatusOutputView.insertText("\n" + actionDescription)
            }
        }
        if case .discovered = action {
            // If the vehicle is discovered, we stop scanning and try to connect to the vehicle.
            tacsManager.stopScanning()
            tacsManager.connect()
        }
    }
    
    private func onVehicleAccessFeatureChange(_ vehicleAccessFeatureChange: VehicleAccessFeatureChange) {
        if case let .responseReceived(response) = vehicleAccessFeatureChange.action {
            if case let .success(status: status) = response {
                DispatchQueue.main.async {
                    self.vehicleStatusOutputView.insertText("\n" + String(describing: status))
                }
            }
        }
    }
    
    private func onConnectionChange(_ connectionChange: TACS.ConnectionChange) {
        DispatchQueue.main.async {
            self.vehicleStatusOutputView.insertText("\n" + String(describing: connectionChange.action))
            // You can also inspect connectionChange.state at any time to check the connection state
        }
    }
    
    private func onTelematicsDataChange(_ telematicsDataChange: TelematicsDataChange) {
        DispatchQueue.main.async {
            self.telematicsOutputView.insertText("\n" + String(describing: telematicsDataChange.action))
        }
    }
    
    private func onKeyholderStatusChange(_ change: KeyholderStatusChange) {
        DispatchQueue.main.async {
            self.keyholderStatusOutputView.insertText("\n" + String(describing: change.action))
        }
    }
    
    private func getStatus() {
        tacsManager.vehicleAccessManager.requestFeature(.lockStatus)
    }
}



//MARK: - String representations
// This section contains conformances to `CustomStringConvertible` for some types.


extension TelematicsData: CustomStringConvertible {
    public var description: String {
        return "timestamp: \(timestamp)\n\(type) = \(value) \(unit)"
    }
}

extension KeyholderInfo: CustomStringConvertible {
    public var description: String {
        return "keyholderId: " + keyholderId.uuidString
            + "\nbatteryVoltage: " + String(batteryVoltage)
            + "\nactivationCount: " + String(activationCount)
            + "\nisCardInserted: " + (isCardInserted ? "true" : "false")
            + "\nbatteryChangeCount: " + String(batteryChangeCount)
    }
}

extension KeyholderStatusError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .bluetoothOff: return "bluetooth device off"
        case .keyholderIdMissing: return "keyholder id is missing"
        case .scanTimeout: return "discovery timed out"
        }
    }
}


extension TACS.ConnectionChange.Action: CustomStringConvertible {
    public var description: String {
        let result: String
        switch self {
        case .initial: result = "Initial action"
        case .connect: result = "Connecting..."
        case .physicalConnectionEstablished: result = "Physical connection established"
        case .transportConnectionEstablished: result = "Transport connection established"
        case .connectionEstablished: result = "Connected"
        case .connectingFailed(vehicleRef: _, error: let error): result = "Connecting failed with error: \(String(describing: error))"
        case .connectingFailedDataMissing: result = "Connecting failed due to missing blob data"
        case .disconnect: result = "Disconnected"
        case .connectionLost(let error): result = "Connection lost with error: \(String(describing: error))"
        }
        return result
    }
}

extension TACS.ConnectingFailedError: CustomStringConvertible {
    public var description: String {
        let result: String
        switch self {
        case .blobOutdated: result = "Blob data is outdated"
        case .challengeFailed: result = "Challenge failed"
        case .invalidMTUResponse: result = "Invalid MTU response"
        case .invalidTimeFrame: result = "Invalid time frame"
        case .physicalConnectingFailed: result = "Physical connecting failed"
        }
        return result
    }
}

extension VehicleAccessFeatureStatus: CustomStringConvertible {
    public var description: String {
        let result: String
        switch self {
        case .disableIgnition: result = "Disable ignition..."
        case .enableIgnition: result = "Enable ignition..."
        case .ignitionStatus(enabled: let enabled): result = enabled ? "Ignition enabled" : "Ignition disabled"
        case .lock: result = "Lock doors..."
        case .unlock: result = "Unlock doors..."
        case .lockStatus(locked: let locked): result = locked ? "Doors locked" : "Doors unlocked"
        }
        return result
    }
}

extension TelematicsDataChange.Action: CustomStringConvertible {
    public var description: String {
        let result: String
        switch self {
        case .initial: result = "Initial action"
        case .requestingData(types: let types): result = "Requesting data with types: \(String(describing: types))"
        case .responseReceived(responses: let responses):
            let responsesDescription = responses.map { String(describing: $0) }.joined(separator: "\n")
            result = "Response received:\n\(String(describing: responsesDescription))"
        }
        return result
    }
}

extension TelematicsDataResponse: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .success(data): return String(describing: data)
        case let .error(type, error): return "\(type) error: \(error)"
        }
    }
}

extension KeyholderStatusChange.Action: CustomStringConvertible {
    public var description: String {
        let result: String
        switch self {
        case .initial: result = "Initial action"
        case .discoveryStarted: result = "Discovery started"
        case .discovered(let info): result = "Discovered keyholder:\n\(String(describing: info))"
        case .failed(let error): result = "Keyholder discovery failed with error:\n\(String(describing: error))"
        }
        return result
    }
}

extension TACS.DiscoveryChange.Action: CustomStringConvertible {
    public var description: String {
        switch self {
        case .startDiscovery: return "Started discovery"
        case .stopDiscovery: return "Stopped discovery"
        case .discovered: return "Discovered vehicle"
        case .missingBlobData: return "Discovery start failed: blob data missing"
        default: return ""
        }
    }
}
