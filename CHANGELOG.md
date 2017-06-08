# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]
### Added

- 2017-06-07 : (PLAM-749)   : New `BLEManagerType` protocol, `SimulatableBLEManager` and `MockBLEManager`

### Changed

- 2017-06-08 : (PLAM-965)   : Don't expose `SID` type to the outside of the framework
- 2017-06-07 : (PLAM-749)   : Let `BLEManager` conform to `BLEManagerType`

### Fixed

## [1.0.8] - 2017-05-24
### Added
### Changed
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
### Changed
- Reconstruction of Framework

### Added
- BLEComManager
- BLECmmunicator
- BLEScanner

### Removed
- BLEManager
- CommunicationManager

### Changed
- Code documentation for BLE Framework

## [1.0.0] - 2016-06-08
### Added
- Initial release
