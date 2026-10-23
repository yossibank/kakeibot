.PHONY: setup open format licenses build test-build test

SIMULATOR ?= $(shell xcrun simctl list devices available iPhone | awk -F '[()]' '/iPhone/ { print $$2; exit }')
XCBEAUTIFY = $(shell command -v xcbeautify)
BEAUTIFY = $(if $(XCBEAUTIFY),| xcbeautify $(XCBEAUTIFY_FLAGS))
CHECKOUT = $(if $(BRANCH),$(shell git worktree list --porcelain | awk '/^worktree / { path = substr($$0, 10) } $$0 == "branch refs/heads/$(BRANCH)" { print path }'),.)

setup:
	brew bundle
	mint bootstrap
	pre-commit install

open:
	@test -n "$(CHECKOUT)" || { echo "$(BRANCH) のワークツリーが無い"; exit 1; }
	open "$(CHECKOUT)/ios/Kakeibot.xcworkspace"

format:
	mint run swiftformat .

licenses:
	cd ios && mint run --mintfile ../Mintfile LicensePlist --xcworkspace-path Kakeibot.xcworkspace --config-path license_plist.yml --output-path Kakeibot/Settings.bundle --add-version-numbers --add-sources --suppress-opening-directory --fail-if-missing-license --force
	rm -f ios/Kakeibot/Settings.bundle/com.mono0926.LicensePlist.latest_result.txt

build:
	set -o pipefail; xcodebuild -workspace ios/Kakeibot.xcworkspace -scheme Kakeibot -destination 'generic/platform=iOS Simulator' build $(BEAUTIFY)

test-build:
	set -o pipefail; xcodebuild -workspace ios/Kakeibot.xcworkspace -scheme Kakeibot -testPlan Kakeibot -destination 'id=$(SIMULATOR)' build-for-testing $(BEAUTIFY)

test:
	set -o pipefail; xcodebuild -workspace ios/Kakeibot.xcworkspace -scheme Kakeibot -testPlan Kakeibot -destination 'id=$(SIMULATOR)' test $(BEAUTIFY)
