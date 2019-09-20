# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

### Added
### Changed
### Fixed
### Removed

## [3.5.2] - 2019-09-20

### Added
- 2019-09-09 : (PLB2B-846)  : Added setup for creating static framework

## [3.5.1] - 2019-08-06
### Added
- 2019-08-06 : (PLB2B-784)  : Added opt out for carthage verbose setting since it can fail in Jenkins environment

### Fixed
- 2019-07-12 : (PLB2B-703)  : Fixed issue where heart beat messages were not enqueued in stress test scenario

## [3.5.0] - 2019-06-18

### Added
- 2019-06-17 : (PLB2B-412)  : Upgrade to Swift 5

## [3.4.0] - 2019-04-03

### Added
- 2019-04-02 : (PLB2B-249)  : Added support for tacs

## [3.3.1] - 2019-01-31

### Added
- 2019-01-30 : (PLCR-790)  : Added possibility to scan for peripherals with manufacturer data containing the company ID

## [3.3.0] - 2018-12-13

### Added
- 2018-12-11 : (PLCR-712)  : Added SORC time check handling

## [3.2.2] - 2018-12-03

### Added
- 2018-11-19 : (PLCR-574)  : Added possibility to scan for peripherals with manufacturer data longer then 16 bytes

### Fixed
- 2018-11-19 : (PLCR-574)  : Fix identification of lost peripherals

## [3.2.1] - 2018-11-02

### Removed
- 2018-11-19 : Removed packaging of fat binary via script

## [3.2.0] - 2018-10-10

### Added
- 2018-10-10 : (PLAM-3393)  : Migrated to Swift 4.2
- 2018-10-10 : (PLAM-3393)  : Upgraded to CryptoSwift 0.12.0

## [3.1.2] - 2018-08-20

### Fixed
- 2018-08-14 : (PLAM-3206)  : Fixed the version number for distribution 

## [3.1.1] - 2018-08-14

### Fixed
- 2018-08-14 : (PLAM-3188)  : Determine the application state if it is not set on discovery start 

## [3.1.0] - 2018-07-11

### Added
- 2018-06-01 : (PLAM-2860)  : Added configuration to create docs for distribution 

### Changed
- 2018-06-28 : (PLAM-2860)  : Updated README.md and LICENSE.md for distribution 

### Fixed
- 2018-07-05 : (PLCR-429)  : Fix issue where cram stage was finished before "data sent" event was received

## [3.0.0] - 2018-06-20

### Added
- 2018-06-01 : (PLAM-2860)  : Migrated to Swift 4.1
- 2018-06-01 : (PLAM-2860)  : Upgraded to CryptoSwift 0.9.0

### Changed
-2018-06-19 : (PLAM-2860)  : Update ACL levels where necessary
-2018-06-14 : (PLAM-2860)  : Updated code documentation

### Fixed
- 2018-06-11 : (PLAM-2860)  : Removed unused libraries which were accidentally added in the past

### Removed
- 2018-06-20 : (PLAM-2860)  : Removed CommonUtils
- 2018-06-01 : (PLAM-2860)  : Removed OpenSSL

## [2.3.0] - 2018-02-23

### Added
- 2018-02-09 : (PLAM-2106)  : Added functionality to scan for peripherals in background

### Fixed
- 2018-02-09 : (PLAM-2282)  : Warnings in dependencies resolved

## [2.2.0] - 2017-12-18

### Added
- 2017-12-01 : (PLAM-1863)  : Avoid running swift format in CI build
- 2017-10-23 : (PLAM-1661)  : Added the new Cocoa Touch Framework target for binary distribution of the library   

### Changed
- 2017-12-05 : (PLAM-1784)  : Updated CryptoSwift to version 0.7.0
- 2017-10-25 : (PLAM-1650)  : Updated the README.md file

### Fixed
- 2017-11-16 : (PLAM-1756)  : Added missing files to the binary framework

## [2.1.0] - 2017-10-16

### Added
- 2017-09-29 : (PLAM-1543)  : Fixed issues found by SwiftLint

## [2.0.0] - 2017-09-27

### Added
- 2017-09-27 : (PLAM-1517)  : Updated logging functionality
- 2017-09-22 : (PLAM-1517)  : Added debug logging functionality
- 2017-09-21 : (PLAM-1568)  : Added tests for `SecurityManager` and `TransportManager`
- 2017-09-07 : (PLAM-1500)  : Added/Fixed jazzy code documentation config
- 2017-09-06 : (PLAM-1071)  : Make constants customizable
- 2017-09-05 : (PLAM-1455)  : Resume scanning after app did enter foreground
- 2017-09-04 : (PLAM-1374)  : Added error handling for sending and receiving data

### Changed
- 2017-10-09 : (PLAM-1539)  : Updated SwiftLint to version 0.23.0
- 2017-08-14 : (PLAM-964)   : Rename `SID` to `SORC`
- 2017-08-14 : (PLAM-962)   : Provide proper actions for disconnected state in `BLEManager`
- 2017-08-11 : (PLAM-961)   : Provide correct rssi through DiscoveryChange
- 2017-08-11 : (PLAM-960)   : Merged sorcDiscovered, sorcsLost and hasSorcId into one subject
- 2017-08-08 : (PLAM-963)   : Improve `BLEScanner` (`SorcConnectionManager`)

## [1.1.0] - 2017-08-22

### Added
- 2017-08-21 : (PLAM-1412)  : Provide method to start discovery again.

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
