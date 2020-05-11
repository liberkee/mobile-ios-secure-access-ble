#!/bin/bash
set -e

run_carthage() {
    BUILD_TYPE=$1
    # CARTHAGE_NO_VERBOSE flag turns off the verbose log of carthage which led to issues in jenkins job,
    # see https://github.com/Carthage/Carthage/issues/2249 for details.
    if [ ! -z "$CARTHAGE_NO_VERBOSE" ]; then
        carthage build --no-skip-current --derived-data DerivedData --log-path carthage_${BUILD_TYPE}.log
    else
        carthage build --no-skip-current --derived-data DerivedData --log-path carthage_${BUILD_TYPE}.log --verbose
    fi
}

prepare_static_framework() {
    echo "Changing MACH_O_TYPE of target to staticlib..." 
    sed -i '' 's/MACH_O_TYPE.*/MACH_O_TYPE = staticlib;/g' SecureAccessBLE.xcodeproj/project.pbxproj 
    echo "Reinstalling pods as static libs..."
    bundle exec pod deintegrate
    sed -i '' 's/use_frameworks!/ /g' Podfile
    bundle exec pod install --verbose
    echo "Pod installiation finished."
}

copy_artifacts() {
    mkdir -p $OUTPUT_PATH
    cp -R ${CARTHAGE_BUILD_PATH}/* $OUTPUT_PATH
    cp -R ../distribution/* $OUTPUT_PATH
}

cd Example
rm -rf ../BUILD Carthage DerivedData

CARTHAGE_BUILD_PATH=Carthage/Build/iOS
OUTPUT_PATH=../BUILD/Dynamic

echo "**********Starting dynamic build**********"
run_carthage dynamic

echo "**********Copying dynamic artefacts**********"
copy_artifacts

echo "**********Cleaning Up dynamic build**********"
rm -rf Carthage DerivedData

# If the build should include static build, build it
if [ -n "$INCLUDE_STATIC_BUILD" ]; then
    OUTPUT_PATH=../BUILD/Static
    CARTHAGE_BUILD_PATH=Carthage/Build/iOS/Static
    echo "**********Preparing static framework**********"
    prepare_static_framework

    echo "**********Starting static build**********"
    run_carthage static

    echo "**********Copying static artefacts**********"
    copy_artifacts
fi