
# Starting from 3.4.0, the repo contains duild script which also copies bitcode symbols
export VERSION_WITH_TACS_SUPPORT=3.4.0
if [ "$VERSION" == "$(npx -q semver $VERSION -r \>=$VERSION_WITH_TACS_SUPPORT)" ]; then

    echo "Building with TACS support..."

	# Build framework using carthage and copy build artefacts into BUILD folder
	# CARTHAGE_NO_VERBOSE flag turns off the verbose log of carthage which led to issues, see https://github.com/Carthage/Carthage/issues/2249 for details
    if [ "$STATIC_BUILD" = true ] ; then
		echo "The build will include a static version..."
    	export INCLUDE_STATIC_BUILD=1
	fi
	CARTHAGE_NO_VERBOSE=1 sh scripts/build_release.sh
	cp -r BUILD Libs
else

    echo "Building without TACS support..."

	cd Example

	# Create archive for both ARM and x86 architectures
	carthage build --no-skip-current

	# Rename/copy files
	cp -r ../distribution ../Libs
	cp -r Carthage/Build/iOS/SecureAccessBLE.framework ../Libs
	cp -r Carthage/Build/iOS/SecureAccessBLE.framework.dSYM ../Libs
	cd ..
fi