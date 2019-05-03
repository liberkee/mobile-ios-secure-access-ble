#!/bin/bash
set -x

rm -rf BUILD
rm -rf Carthage
carthage build --no-skip-current --verbose
mkdir -p BUILD
cp -R Carthage/Build/iOS/* BUILD
cp -R distribution/* BUILD