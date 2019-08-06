#!/bin/bash
set -xe

rm -rf BUILD
cd Example
rm -rf Carthage

# CARTHAGE_NO_VERBOSE flag turns off the verbose log of carthage which led to issues in jenkins job,
# see https://github.com/Carthage/Carthage/issues/2249 for details.

if [ ! -z "$CARTHAGE_NO_VERBOSE" ]; then
    carthage build --no-skip-current
else
    carthage build --no-skip-current --verbose
fi

mkdir -p ../BUILD
cp -R Carthage/Build/iOS/* ../BUILD
cp -R ../distribution/* ../BUILD