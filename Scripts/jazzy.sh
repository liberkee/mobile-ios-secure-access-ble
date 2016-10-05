#!/bin/sh

#  jazzy.sh
#  SecureAccessBLE
#
#  Created by Lars Hosemann on 03.10.16.
#  Copyright © 2016 Huf Secure Mobile GmbH. All rights reserved.

jazzy \
  --clean \
  --author 'Huf Secure Mobile GmbH' \
  --github_url "https://github.com/hufsm/mobile-ios-ble" \
  --xcodebuild-arguments -workspace,./../Example/SecureAccessBLE.xcworkspace,-scheme,SecureAccessBLE \
  --module 'SecureAccessBLE' \
  --output '../Docs' \
  --min-acl 'internal' # Could also be 'private'
