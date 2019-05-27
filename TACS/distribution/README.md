# TACS

## Description
Framework for communicating with the TACS.

## Prerequisites
* [Xcode 10.1](https://developer.apple.com/xcode/ide/)
* [CocoaPods](https://cocoapods.org)

## License
Copyright (c) 2018-present, Huf Secure Mobile GmbH

The software contained within this package, including all enclosed library releases, documentation and source files ("the software") is provided solely for the purpose of evaluation of Huf Secure Mobile GmbH ("HSM") software, hardware and services by organizations or individuals directly and explicitly authorized by HSM to receive and evaluate this software. Any commercial application or redistribution is prohibited. The software remains the sole intellectual property of HSM.


THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Prerequisites
* [Xcode 10.1](https://developer.apple.com/xcode/ide/)
* [CocoaPods 1.6.0](https://cocoapods.org)

## Dependencies
* [CryptoSwift](https://github.com/krzyzanowskim/CryptoSwift) - [zlib License](https://github.com/krzyzanowskim/CryptoSwift/blob/master/LICENSE)
* `SecureAccessBLE`

## Installation

The easiest way is to integrate the SDK via CocoaPods but you can also set up your project manually if you prefer. In that case, you'll need to also integrate `CryptoSwift` manually.

### Via CocoaPods
Copy both `SecureAccessBLE` and `TACS` folders into your project folder. The folders contain `.podspec` files which you need to point to in your `Podfile`.
Add following to your app target in the podfile by replacing `PATH_TO_FRAMEWORK` with appropriate folder:

```ruby
pod 'SecureAccessBLE', :path => 'PATH_TO_FRAMEWORK'
pod 'TACS', :path => 'PATH_TO_FRAMEWORK'
```

### Manually
Since the SDK depends on `CryptoSwift` framework, you will first need to install the dependency.
1. Install `CryptoSwift` by following the instruction [here](https://github.com/krzyzanowskim/CryptoSwift#installation)
2. Add `SecureAccessBLE.framework` and `TACS.framework` to your project by dragging in into Xcode.
3. Add `SecureAccessBLE.framework` and `TACS.framework` to embedded binaries section of your App target.


Since the frameworks are referenced locally, ithey will appear in `Development Pods` group in the Xcode Workspace. For more information about the usage of CocoaPods visit [this page](https://guides.cocoapods.org/using/using-cocoapods).

## Usage

### General

* Import `SecureAccessBLE` and `TACS` in the source code

```swift
import SecureAccessBLE
import TACS
```

* Use `TACSManager` as general entry point to the framework

```swift
let tacsManager = TACSManager()
```

* Subscribe to changes of interest. 
The `TACSManager` as well as its helpers `VehicleAccessManager`, `TelematicsManager`, `KeyholderManager` provide an API which works asynchronously. All events will be notified as changes via appropriate signals. 

Signals are either state signals (in case of `isBluetoothEnabled` signal) which only sends values or change signals (in case of all other signals) which contain current state and the action which led to this state.

Use an instance of `DisposeBag` to dispose subscriptions. 
You can have a stored property in your class. If the class and its stored properties are deinitialized, all subscriptions will be removed.

```swift
let disposeBag = DisposeBag()
```

To subscribe, call `subscribe` on a signal and provide a closure for handling the signal change.
Here is an example of subscription to `isBluetoothEnabled` signal:

```swift
tacsManager.isBluetoothEnabled.subscribe { [weak self] bluetoothOn in
    // handle bluetooth state change
}
.disposed(by: disposeBag) // add disposable to a disposeBag which will take care about removing subscriptions on deinit
```

### Prepare necessary lease data

* Ensure you have required `TACSKeyRing` instance and corresponding `vehicleAccessGrnatId`.

`TACSKeyRing` struct conforms to `Decodable` protocol which means you can simply create an instance from JSON:

```swift
let jsonData = ... // JSON as Data instance from my API
let keyRing = try? JSONDecoder().decode(TACSKeyRing.self, from: jsonData)
```

* Use `TACSKeyRing` and `vehicleAccessGrnatId`

### Handling adapter state

* Subscribe to bluetooth adapter state change

```swift
tacsManager.isBluetoothEnabled.subscribe { [weak self] bluetoothOn in
    // handle bluetooth state change
}
```

### Scanning for vehicle

* Subscribe to discovery change events

```swift
tacsManager.discoveryChange.subscribe { discoveryChange in
    // handle discovery state changes
    if discoveryChange.action == .discovered {
       // start connecting
    }
}
```
* Start scanning

```
tacsManager.startScanning()
```

### Establish connection

* Subscribe to connection change events

```swift
tacsManager.connectionChange.subscribe { connectionChange in
    // handle connection changes
}
```

* Start connection

```swift
tacsManager.connect()
```

### Request vehicle features

* Subscribe to vehicle access change events

```swift
tacsManager.vehicleAccessManager.vehicleAccessChange.subscribe { [weak self] vehicleAccessChange in
    // handle vehicle access changes
}
```

* Request vehicle access feature

```swift
tacsManager.vehicleAccessManager.requestFeature(.lock)
```

## Request telematics data

* Subscribe to telematics data change events

```swift
tacsManager.telematicsManager.telematicsDataChange.subscribe { [weak self] telematicsDataChange in
    // handle telematics data changes
}
```

* Request telematics data

```swift
tacsManager.telematicsManager.requestTelematicsData([.odometer, .fuelLevelAbsolute, .fuelLevelPercentage])
```

### Request keyholder state

* Subscribe to keyholder state change events

```swift
tacsManager.keyholderManager.keyholderChange.subscribe { [weak self] change  in
    // handle keyholder state changes
}
```

* Request keyholder state

```swift
tacsManager.keyholderManager.requestStatus(timeout: 10.0)
```