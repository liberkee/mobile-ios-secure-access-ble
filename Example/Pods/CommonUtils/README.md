# mobile-ios-common-utils

Shared methods for iOS Frameworks

## Installation
CommonUtils is available through the [private pod spec repo of Huf Secure Mobile GmbH](https://github.com/hufsm/mobile-ios-podspecs). To install
it, simply add the following lines to your Podfile:
```ruby
source 'https://github.com/hufsm/mobile-ios-podspecs.git'

pod 'CommonUtils'
```

As a developer of the framework, you can install the bleeding edge version of a specific branch by adding the following line to your Podfile:
```ruby
pod 'CommonUtils', :git => 'https://github.com/hufsm/mobile-ios-common-utils.git', :branch => 'develop'
```
or
```ruby
pod 'CommonUtils', :git => 'https://github.com/hufsm/mobile-ios-common-utils', :commit => 'xxxxxx'
```

## Development and Testing
Follow these steps in order to start developing and testing the framework:
- Clone the repository
- Run `bundle install` from the root of the repository to install the required gem versions
- Run `pod install` from the Example subdirectory to install the pods

To publish a new version of the framework you need to:
- (Once only) Add the private podspec repo to your local machine by running `pod repo add hsm-specs https://github.com/hufsm/mobile-ios-podspecs.git`
- Add a proper version git tag for the new release and update the version in the podspec file accordingly
- Push the new version to the private podspec repository by running `pod repo push hsm-specs CommonUtils.podspec` from the root of the repository

## Jazzy Docs
This project uses [Jazzy](https://github.com/realm/jazzy) to generate the documentation. To update the documentation you need to:
- Run `bundle install` to install the jazzy gem
- `cd` into the `ProjectRoot/Scripts` directory
- Run `sh jazzy.sh` to regenerate the documentation
