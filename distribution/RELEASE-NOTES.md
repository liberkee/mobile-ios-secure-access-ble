# [3.13.0] - 2020-04-14

- Added bulk message transfer

# [3.12.0] - 2020-04-02

- Added support for Xcode 11.4

# [3.11.0] - 2020-03-20

- Added timeout handling for discovery

# [3.10.0] - 2020-02-25

- Added `notConnected` error case for scenario where a service grant is requested in not connected state
- Added bluetooth state events to tracking

# [3.9.0] - 2020-02-17

- Added Event tracking to the SDK
- The library doesn't send `.lost` discovery changes if the discovery was stopped

# [3.8.1] - 2020-01-24

- Added support for Xcode 11.3

# [3.8.0] - 2019-11-22

- Support for Xcode 11.2
- The `isBluetoothEnabled` signal of `SorcManager` was replaced with `bluetoothState` signal which provides new `BluetoothState` enum. This especially simplifies handling of `unauthorized` state of BLE interface which became important in iOS 13.

# [3.7.0] - 2019-10-30

- Fixed issue where SDK did an attempt to negotiate the MTU size twice
- Simplified connection change events of SorcManager by removing MTU size as well as transport connection related events. 

# [3.6.1] - 2019-10-10

- Fixed issue where code documentation was missing symbols

# [3.6.0] - 2019-09-27

- Added support for Xcode 11

# [3.5.2] - 2019-09-20

- Added minor improvements to build tools

# [3.5.1] - 2019-07-17

- Fix issue where a disconnection could happen in a stress test scenario

# [3.4.0] - 2019-05-24

- Added ability to provide background queue to SorcManager

# [3.3.1] - 2019-01-31

- Added support for the new BLE advertisment protocol which contains the company identifier

# [3.3.0] - 2018-12-13

- The library now explicitly communicates expired leases instead of reporting them as generic security errors / service grant denied.

# [3.2.2] - 2018-12-03

- Added a fix for identification of lost peripherals

# [3.2.1] - 2018-11-02

- Added debug symbols

# [3.2.0] - 2018-10-11

- Updated for Xcode 10 and Swift 4.2

# [3.1.2] - 2018-08-20

- Fixed the version number for distribution 

# [3.1.1] - 2018-08-14

- Fixed a bug where discovery could fail if the library setup was executed after app start

# [3.1.0] - 2018-07-11

- Fixed issue where grant could not be sent immediately after connected event and required a delay
