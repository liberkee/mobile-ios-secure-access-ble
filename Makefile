.DEFAULT_GOAL := help

LIBRARY_NAME := SecureAccessBLE

#help: @ 📖 Lists available tasks on this project
help:
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(MAKEFILE_LIST)| tr -d '#'  | awk 'BEGIN {FS = ":.*?@ "}; {printf "\033[36m%-30s\033[0m %s\n\n", $$1, $$2}'

#setup:	@ ⚡️ Runs initial setup
setup:
	bundle config path vendor/bundle
	bundle update --jobs 4 --retry 3
	cd Example && exec pod update

#lint: @ 💄 Runs linter
lint:
	cd Example && Pods/SwiftLint/swiftlint lint --reporter html --config ../.swiftlint.yml > ../lint_reports/swiftlint_report.html

#test: @ ✅ Runs all tests
test:
	cd Example && bundle exec fastlane scan

#coverage: @ 📊 Creates coverage reports
coverage:
	bundle exec slather

#documentation.generate: @ 💡 Generates documentation
documentation.generate:
	bundle exec jazzy

version:
	@bundle exec pod ipc spec ${LIBRARY_NAME}.podspec | jq -r '.version'

#build: @ 📦 Builds the library
build:
	cd Example && \
	xcodebuild -workspace "${LIBRARY_NAME}.xcworkspace" \
	-scheme "${LIBRARY_NAME}" \
    -configuration "Release" \
    -destination generic/platform=iOS \
    ONLY_ACTIVE_ARCH=NO \
    ENABLE_BITCODE=YES \
    OTHER_CFLAGS="-fembed-bitcode" \
    BITCODE_GENERATION_MODE=bitcode \
    clean build