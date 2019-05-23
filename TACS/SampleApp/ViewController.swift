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
    
    var vehicleDiscovered = false
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var telematicsOutputView: UITextView!
    @IBOutlet weak var keyholderStatusOutputView: UITextView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let queue = DispatchQueue(label: "com.queue.blehandling")
        tacsManager = TACSManager(queue: queue)
        
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
        
        tacsManager.vehicleAccessManager.vehicleAccessChange.subscribe { [weak self] vehicleAccessChange in
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
        // Start scanning for vehicles
        tacsManager.startScanning()
    }
    
    @IBAction func lockDoors(_ sender: Any) {
        tacsManager.vehicleAccessManager.requestFeature(.lock)
    }
    
    @IBAction func unlockDoors(_ sender: Any) {
        tacsManager.vehicleAccessManager.requestFeature(.unlock)
    }
    
    @IBAction func getTelematicsData(_ sender: Any) {
        tacsManager.telematicsManager.requestTelematicsData([.odometer, .fuelLevelAbsolute, .fuelLevelPercentage])
    }
    
    @IBAction func requestKeyholderStatus(_ sender: Any) {
        keyholderStatusOutputView.text = ""
        tacsManager.keyholderManager.requestStatus(timeout: 10.0)
    }
    
    private func onDiscoveryChange(_ discoveryChange: TACS.DiscoveryChange) {
        switch discoveryChange.action {
        case .discovered(vehicleRef: let vehicleRef):
            // If the vehicle is discovered, we stop scanning and try to connect to the vehicle.
            vehicleDiscovered = true
            tacsManager.stopScanning()
            connect()
        default: break
        }
    }
    
    private func onVehicleAccessFeatureChange(_ vehicleAccessFeatureChange: VehicleAccessFeatureChange) {
        var statusText: String?
        if case let .responseReceived(response) = vehicleAccessFeatureChange.action {
            if case let .success(status: status) = response {
                switch status {
                case .lock:
                    statusText = "Locked"
                case .unlock:
                    statusText = "Unlocked"
                case .enableIgnition: // update UI if needed
                    break
                case .disableIgnition: // update UI if needed
                    break
                case .lockStatus(let locked):
                    statusText = locked ? "Locked" : "Unlocked"
                case .ignitionStatus(let enabled): // update UI if needed
                    break
                }
            }
        }
        if let text = statusText {
            DispatchQueue.main.async {
                self.statusLabel.text = text
            }
        }
    }
    
    private func onConnectionChange(_ connectionChange: TACS.ConnectionChange) {
        let statusText: String
        switch connectionChange.state {
        case .disconnected:
            statusText = "Disconnected"
            print("Sorc disconnected")
        case .connecting(let sorcID, let state):
            statusText = "Connecting..."
            print("Connecting to sorc with id \(sorcID). Current state \(state)")
        case .connected(let sorcID):
            statusText = "Connected"
            print("Connected to sorc with id \(sorcID)")
            getStatus()
        }
        DispatchQueue.main.async {
            self.statusLabel.text = statusText
        }
    }
    
    private func onTelematicsDataChange(_ telematicsDataChange: TelematicsDataChange) {
        print("Telematics data change with state:")
        if telematicsDataChange.state.count > 0 {
            print("Requesting telematics data with types: \(telematicsDataChange.state)")
        } else {
            print("No telematics data requests pending")
        }
        print("Action:")
        switch telematicsDataChange.action {
        case .initial:
            print("Initial telematics change")
        case let .requestingData(types: types):
            print("Requesting data with types \(types)")
        case let .responseReceived(responses: responses):
            print("Response received with telematics responses: \(responses)")
            DispatchQueue.main.async {
                self.telematicsOutputView.text = self.outputStringFromTelematicsData(responses)
            }
        }
    }
    
    private func onKeyholderStatusChange(_ change: KeyholderStatusChange) {
        let outputText: String
        switch change.action {
        case .initial:
            outputText = "\nInitial action"
        case .discoveryStarted:
            outputText = "\nDiscovery started"
        case .discovered(let keyholderInfo):
            outputText = "\nDiscovered keyholder:\n" + String(describing: keyholderInfo)
        case .failed(let error):
            outputText = "\nDiscovery failed with error:\n" + String(describing: error)
            break
        }
        DispatchQueue.main.async {
            self.keyholderStatusOutputView.insertText(outputText)
        }
    }
    
    private func connect() {
        guard vehicleDiscovered == true else { return }
        tacsManager.connect()
    }
    
    private func getStatus() {
        tacsManager.vehicleAccessManager.requestFeature(.lockStatus)
    }
    
    private func outputStringFromTelematicsData(_ responses: [TelematicsDataResponse]) -> String {
        let result: [String] = responses.map { response in
            switch response {
            case let .success(data):
                return String(describing: data)
            case let .error(type, error):
                return "\(type) error: \(error)"
            }
        }
        return result.joined(separator: "\n\n")
    }
}

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
