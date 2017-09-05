# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [2.0.0] - Unreleased

### Added
- 2017-09-05 : (PLAM-1455)  : Resume scanning after app did enter foreground
- 2017-09-04 : (PLAM-1374)  : Added error handling for sending and receiving data

### Changed
- 2017-08-14 : (PLAM-964)   : Rename `SID` to `SORC`
- 2017-08-14 : (PLAM-962)   : Provide proper actions for disconnected state in `BLEManager`
- 2017-08-11 : (PLAM-961)   : Provide correct rssi through DiscoveryChange
- 2017-08-11 : (PLAM-960)   : Merged sorcDiscovered, sorcsLost and hasSorcId into one subject
- 2017-08-08 : (PLAM-963)   : Improve `BLEScanner` (`SorcConnectionManager`)

### Removed
### Fixed

## [1.0.14] - 2017-08-02

### Changed
- 2017-08-01 : (PLAM-1219)  : Rewrite all enum values to lowerCase

## [1.0.13] - 2017-07-31

### Changed
- 2017-07-31 : (PLAM-1309)  : Use git@ scheme to access the private pods repo
- 2017-07-31 : (PLAM-1169)  : Updated Cocoapods version to 1.2.1 in Gemfile
- 2017-07-15 : (PLAM-1237)  : Allow `CommonUtils` `0.0.5` and above (`0.0.6` only before) 

## [1.0.12] - 2017-07-24

### Fixed
- 2017-07-17 : (PLAM-1230)  : "disconnect while connecting" leads to a "connected" state and not to "disconnected".

## [1.0.11] - 2017-06-26

### Fixed
- 2017-06-23 : (PLAM-1112)  : Disconnect transporter if heartbeat check failed

## [1.0.10] - 2017-06-18

### Changed
- 2017-06-14 : (PLAM-1045)  : Don't remove discovered and unconnected SORCs on disconnect
- 2017-06-13 : (PLAM-965)   : Don't expose `SID` type to the outside of the framework

## [1.0.9] - 2017-06-13

### Added
- 2017-06-12 : (PLAM-999)   : Let BLEManager respond with errors if communication is blocked by a heartbeat
- 2017-06-07 : (PLAM-749)   : New `BLEManagerType` protocol, `SimulatableBLEManager` and `MockBLEManager`

### Changed
- 2017-06-07 : (PLAM-749)   : Let `BLEManager` conform to `BLEManagerType`

## [1.0.8] - 2017-05-24
### Fixed
- 2017-05-24 : (PLAM-898)   : Fixed crash on decrypting messages with no MAC

## [1.0.7] - 2017-05-17
### Fixed
- 2017-05-17 : (PLAM-820)   : MTU size was read out wrong in release versions


## [1.0.6] - 2017-05-04
### Changed
- 2017-04-25 : (PLAM-749)   : Changed parts of the public API

## [1.0.5] - 2017-04-12
### Added
- 2017-03-28 : (PLAM-576)   : Added possibility to record connection setup success and error

### Changed
- 2017-03-21 : (PLAM-570)   : Changed to secure access api/ble v4

### Fixed

## [1.0.4] - 2017-02-28
### Fixed
- 2017-02-28 : (PLAM-464)   : Fixed bluetooth delegate

## [1.0.3] - 2012-02-28
### Added
- 2017-02-28 : (PLAM-464)   : Added bluetooth delegate

## [1.0.2] - 2016-08-02
### Changed
- Complete documentation
- More tests for CryptoManager
- More tests for BleManager

## [1.0.1] - 2016-07-01

### Added
- BLEComManager
- BLECmmunicator
- BLEScanner

### Removed
- BLEManager
- CommunicationManager

### Changed
- Reconstruction of Framework
- Code documentation for BLE Framework

## [1.0.0] - 2016-06-08
### Added
- Initial release
