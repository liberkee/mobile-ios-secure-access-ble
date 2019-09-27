#
# Be sure to run `pod lib lint SecureAccessBLE.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SecureAccessBLE'
  s.version          = '3.6.0'
  s.summary          = 'SecureAccess BLE framework'
  s.description      = 'Framework for communicating with the SecureAccess BLE hardware.'

  s.homepage         = 'https://www.huf-sixsense.com'
  s.license          = { :file => 'LICENSE.md' }
  s.author           = 'Huf Secure Mobile GmbH'
  s.source           = { :path => './' }
  s.ios.deployment_target = '10.3'

  s.frameworks = 'CoreBluetooth'

  s.dependency 'CryptoSwift', '1.0.0'
  s.ios.vendored_frameworks = 'SecureAccessBLE.framework'
  s.swift_version = '5.1'
  
end
