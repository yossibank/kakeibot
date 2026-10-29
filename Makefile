.PHONY: setup open format licenses build test-build test snapshot verify

SIMULATOR ?= $(shell scripts/simulator.sh)
XCBEAUTIFY = $(shell command -v xcbeautify)
BEAUTIFY = $(if $(XCBEAUTIFY),| xcbeautify)
CLAUDE_CONFIG ?= $(HOME)/Applications/AI/claude-config
SNAPSHOT ?=
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
	@test -n "$(SIMULATOR)" || { echo "NG iPhone のシミュレーターが無い。SIMULATOR に UDID を渡す"; exit 1; }
	set -o pipefail; xcodebuild -workspace ios/Kakeibot.xcworkspace -scheme Kakeibot -testPlan Kakeibot -destination 'id=$(SIMULATOR)' build-for-testing $(BEAUTIFY)

test:
	@test -n "$(SIMULATOR)" || { echo "NG iPhone のシミュレーターが無い。SIMULATOR に UDID を渡す"; exit 1; }
	set -o pipefail; xcodebuild -workspace ios/Kakeibot.xcworkspace -scheme Kakeibot -testPlan Kakeibot -destination 'id=$(SIMULATOR)' -collect-test-diagnostics never test $(BEAUTIFY)

snapshot:
	@test -n "$(SNAPSHOT)" || { echo "NG SNAPSHOT に .claude/snapshots/ の下のセットの名前を渡す"; exit 1; }
	$(CLAUDE_CONFIG)/skills/ui-snapshot/scripts/render-snapshots.sh ios/Packages/KakeibotApp .claude/snapshots/$(SNAPSHOT) .build/snapshots/$(SNAPSHOT)

verify:
	scripts/verify.sh docs-check scripts/docs-check.py
	scripts/verify.sh kit-test swift test --package-path ios/Packages/KakeibotKit
	scripts/verify.sh app-build xcodebuild -workspace ios/Kakeibot.xcworkspace -scheme Kakeibot -destination 'generic/platform=iOS Simulator' build
