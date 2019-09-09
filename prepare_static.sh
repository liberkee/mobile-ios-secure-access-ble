CURRENT_TAG=$(git describe --exact-match --tags HEAD)
if [ ! -z "$CURRENT_TAG" ]; then
    set -e
    echo "Current tag is ${CURRENT_TAG}"
    BRANCH_NAME=release/${CURRENT_TAG}_static_framework
    echo "Creating branch ${BRANCH_NAME}"
    git checkout -b release/${CURRENT_TAG}_static_framework
    cd Example
    echo "Changing MACH_O_TYPE of target to staticlib..." 
    sed -i '' 's/MACH_O_TYPE.*/MACH_O_TYPE = staticlib;/g' SecureAccessBLE.xcodeproj/project.pbxproj 
    echo "Reinstalling pods as static libs..."
    bundle exec pod deintegrate
    sed -i '' 's/use_frameworks!/ /g' Podfile
    bundle exec pod install --verbose
    echo "Pod installiation finished."
    echo "Commit..."
    git add .
    git commit -m "Prepare static release ${CURRENT_TAG}"
    git push --set-upstream origin ${BRANCH_NAME}
    git tag ${CURRENT_TAG}_static_framework
    git push origin ${CURRENT_TAG}_static_framework
else 
    echo "No tag found. This script should only be executed on a commit which contains tag."
fi

