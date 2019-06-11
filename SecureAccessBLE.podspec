#
# Be sure to run `pod lib lint SecureAccessBLE.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SecureAccessBLE'
  s.version          = '3.3.2'
  s.summary          = 'SecureAccess BLE framework'
  s.description      = 'Framework for communicating with the SecureAccess BLE hardware.'

  s.homepage         = 'https://github.com/hufsm/mobile-ios-ble'
  s.license          = { :type => 'Copyright', :text => 'Copyright (c) 2019 Huf Secure Mobile GmbH. All rights reserved.' }
  s.author           = { 'Huf Secure Mobile GmbH' => 'info@hufsecuremobile.com' }
  s.source           = { :git => 'https://github.com/hufsm/mobile-ios-ble.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'

  s.source_files = 'SecureAccessBLE/Classes/**/*'

  s.dependency 'CryptoSwift', '1.0.0'
  
  s.swift_version = '5.0'
end
