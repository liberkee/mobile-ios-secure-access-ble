#
# Be sure to run `pod lib lint SecureAccessBLE.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SecureAccessBLE'
  s.version          = '2.3.0'
  s.summary          = 'SecureAccess BLE framework'
  s.description      = 'Framework for communicating with the SecureAccess BLE hardware.'

  s.homepage         = 'https://github.com/hufsm/mobile-ios-ble'
  s.license          = { :type => 'Copyright', :text => 'Copyright (c) 2017 Huf Secure Mobile GmbH. All rights reserved.' }
  s.author           = { 'Huf Secure Mobile GmbH' => 'info@hufsecuremobile.com' }
  s.source           = { :git => 'https://github.com/hufsm/mobile-ios-ble.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'

  s.source_files = 'SecureAccessBLE/Classes/**/*'

  s.vendored_frameworks = [ 'SecureAccessBLE/Frameworks/openssl.framework' ]

  s.dependency 'CommonUtils', '0.1.2'

  s.dependency 'CryptoSwift', '0.7.0'
  
end
