# TACS
[![Build Status](https://jenkins01.hufsm.com/buildStatus/icon?job=mobile/iOS%20development/SecureAccessBLE%20-%20Tests)](https://jenkins01.hufsm.com/job/mobile/job/iOS%20development/job/SecureAccessBLE%20-%20Tests/)

## Description
Framework for communicating with the TACS.

## Prerequisites
* [Xcode 10.1](https://developer.apple.com/xcode/ide/)
* [Bundler](http://bundler.io)
* [CocoaPods](https://cocoapods.org)
* [Jazzy](https://github.com/realm/jazzy)

## License
Copyright © 2018 Huf Secure Mobile GmbH. All rights reserved.

## Dependencies

* `SecureAccessBLE`

### 3rd party frameworks
* [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) - [zlib License](https://github.com/nicklockwood/SwiftFormat/blob/master/LICENCE.md)
* [SwiftLint](https://github.com/realm/SwiftLint) - [MIT License](https://github.com/realm/SwiftLint/blob/master/LICENSE)

## Build instructions
### Create binary framework
You can create the framework by running
```bash
carthage build --no-skip-current
```
in the project root.

The output can be found in `Carthage/Build/iOS` folder by default.
### Installation

To install the framework in the project via Cocoapods
* copy contents of `Carthage/Build/iOS` and `distribution` folders in one folder, e.g. `Libs/TACS` 
* reference the folder in your project

Since both `SecureAccessBLE` and `TACS` frameworks are necessary, a `Podfile` would look like

```ruby
pod 'SecureAccessBLE', :path => '../Libs/SecureAccessBLE' # Refer to Readme.md of SecureAccessBLE for more options on this.
pod 'TACS', :path => '../Libs/TACS'
```

Run 
```ruby
pod install
```
in your project root.

### Documentation
This project uses [Jazzy](https://github.com/realm/jazzy) to generate the documentation. To update the documentation you need to:

- Run `bundle install` to install the jazzy gem
- Run `jazzy` to generate the documentation
