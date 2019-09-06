#!/bin/bash
set -xe

cd Example
rm -rf ../BUILD Carthage DerivedData

if [ ! -z "$STATIC_BUILD" ]; then
    OUTPUT_PATH=../BUILD/Dynamic
    CARTHAGE_BUILD_PATH=Carthage/Build/iOS
else
    OUTPUT_PATH=../BUILD/Static
    CARTHAGE_BUILD_PATH=Carthage/Build/iOS/Static
fi

# CARTHAGE_NO_VERBOSE flag turns off the verbose log of carthage which led to issues in jenkins job,
# see https://github.com/Carthage/Carthage/issues/2249 for details.
if [ ! -z "$CARTHAGE_NO_VERBOSE" ]; then
    carthage build --no-skip-current --derived-data DerivedData --log-path carthage.log
else
    carthage build --no-skip-current --derived-data DerivedData --log-path carthage.log --verbose
fi

mkdir -p $OUTPUT_PATH
cp -R ${CARTHAGE_BUILD_PATH}/* $OUTPUT_PATH
cp -R ../distribution/* $OUTPUT_PATH