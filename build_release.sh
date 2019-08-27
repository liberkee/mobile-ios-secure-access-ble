#!/bin/bash
set -xe

rm -rf BUILD
cd Example
rm -rf Carthage

function run_carthage {
    # CARTHAGE_NO_VERBOSE flag turns off the verbose log of carthage which led to issues in jenkins job,
    # see https://github.com/Carthage/Carthage/issues/2249 for details.
    if [ ! -z "$CARTHAGE_NO_VERBOSE" ]; then
        carthage build --no-skip-current
    else
        carthage build --no-skip-current --verbose
    fi
}

echo "Building dynamic framework..."
run_carthage
mkdir -p ../BUILD/Dynamic
cp -R Carthage/Build/iOS/* ../BUILD/Dynamic
cp -R ../distribution/* ../BUILD/Dynamic

echo "Building static framework..."
mkdir -p ../BUILD/Static

echo "Changing MACH_O_TYPE of target to staticlib..." 
sed -i '' 's/MACH_O_TYPE.*/MACH_O_TYPE = staticlib;/g' SecureAccessBLE.xcodeproj/project.pbxproj 
echo "Reinstalling pods as static libs..."
bundle exec pod deintegrate
sed -i '' 's/use_frameworks!/ /g' Podfile
bundle exec pod install --verbose
run_carthage

cp -R Carthage/Build/iOS/Static/ ../BUILD/Static
cp -R ../distribution/* ../BUILD/Static