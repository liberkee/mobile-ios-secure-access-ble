# SecureAccessBLE
Framework for communicating with the SecureAccess BLE hardware.

## Installation
SecureAccessBLE is available through the [private pod spec repo of Huf Secure Mobile GmbH](https://github.com/hufsm/mobile-ios-podspecs). To install
it, simply add the following lines to your Podfile:
```ruby
source 'https://github.com/hufsm/mobile-ios-podspecs.git'

pod 'SecureAccessBLE'
```

As a developer of the framework, you can install the bleeding edge version of a specific branch by adding the following line to your Podfile:
```ruby
pod 'SecureAccessBLE', :git => 'https://github.com/hufsm/mobile-ios-ble.git', :branch => 'develop'
```
or
```ruby
pod 'SecureAccessBLE', :git => 'https://github.com/hufsm/mobile-ios-ble.git', :commit => 'xxxxxx'
```

## Development and Testing
Follow these steps in order to start developing and testing the framework:
- Clone the repository
- Run `bundle install` from the root of the repository to install the required gem versions
- Run `pod install` from the Example subdirectory to install the pods

To publish a new version of the framework you need to:
- (Once only) Add the private podspec repo to your local machine by running `pod repo add hsm-specs https://github.com/hufsm/mobile-ios-podspecs.git`
- Add a proper version git tag for the new release and update the version in the podspec file accordingly
- Push the new version to the private podspec repository by running `pod repo push hsm-specs SecureAccessBLE.podspec` from the root of the repository

## Jazzy Docs
This project uses [Jazzy](https://github.com/realm/jazzy) to generate the documentation. To update the documentation you need to:
- Run `bundle install` to install the jazzy gem
- `cd` into the `ProjectRoot/Scripts` directory
- Run `sh jazzy.sh` to regenerate the documentation

## OpenSSL
This project uses a bundled version of OpenSSL which is linked as a framework. In order to create a new version of the OpenSSL framework download the [OpenSSL-for-iOS](https://github.com/x2on/OpenSSL-for-iPhone) project and execute the scripts `build-libssl.sh` and `create-openssl-framework.sh`.

As OpenSSL is written in `C`, we need to include it in our Swift framework using a `module.map` (Bridging-Headers are currently not supported in Swift frameworks). Add the following `module.map` to the OpenSSL framework bundle:
```ruby
module OpenSSL [system] [extern_c] {
    header "Headers/cmac.h"
    export *
}
```
