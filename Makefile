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

documentation.generate.distribution:
	bundle exec jazzy --min-acl public --config .jazzy-dist.yaml

version:
	@bundle exec pod ipc spec ${LIBRARY_NAME}.podspec | jq -r '.version'

clean:
	rm -rf Libs Docs BUILD Example/Carthage

#build: @ ⚙️  Builds the library
build:
	sh scripts/build.sh

watermark.add:
	sh scripts/add_watermark.sh

#version.update: @ ⬆️  Updates the version inside the library's plist
version.update:
	/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION}" Example/${LIBRARY_NAME}/Info.plist

#archive: @ 📦 Archives the build for distribution
archive:
	rm -f "Libs/Dynamic/README.md" "Libs/Dynamic/RELEASE-NOTES.md"
	rm -f "Libs/Static/README.md" "Libs/Static/RELEASE-NOTES.md"
	rm -f "Libs/README.md" "Libs/RELEASE-NOTES.md"
	zip -r ${LIBRARY_NAME}.zip Docs Libs
