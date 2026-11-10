.PHONY: setup open format licenses build test-build test snapshot android-build android-test verify verify-docs

SIMULATOR ?= $(shell scripts/find-simulator.sh)
XCBEAUTIFY = $(shell command -v xcbeautify)
BEAUTIFY = $(if $(XCBEAUTIFY),| perl -pe 's/\xe2\x80\x8b//g' | xcbeautify)
XCODEBUILD = xcodebuild -workspace ios/Kakeibot.xcworkspace -scheme Kakeibot
ANY_SIMULATOR = -destination 'generic/platform=iOS Simulator'
ON_SIMULATOR = -destination 'id=$(SIMULATOR)'
CLAUDE_CONFIG ?= $(HOME)/Applications/AI/claude-config
SNAPSHOT ?=
ANDROID_JAVA_HOME ?= /Applications/Android Studio.app/Contents/jbr/Contents/Home
ANDROID_HOME ?= $(HOME)/Library/Android/sdk
GRADLE = env JAVA_HOME="$(ANDROID_JAVA_HOME)" ANDROID_HOME="$(ANDROID_HOME)" android/gradlew -p android --console=plain
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
	scripts/json-format.sh write

licenses:
	cd ios && mint run --mintfile ../Mintfile LicensePlist --xcworkspace-path Kakeibot.xcworkspace --config-path license_plist.yml --output-path Kakeibot/Settings.bundle --add-version-numbers --add-sources --suppress-opening-directory --fail-if-missing-license --force
	rm -f ios/Kakeibot/Settings.bundle/com.mono0926.LicensePlist.latest_result.txt

build:
	set -o pipefail; $(XCODEBUILD) $(ANY_SIMULATOR) build $(BEAUTIFY)

test-build:
	@test -n "$(SIMULATOR)" || { echo "NG iPhone のシミュレーターが無い。SIMULATOR に UDID を渡す"; exit 1; }
	set -o pipefail; $(XCODEBUILD) -testPlan Kakeibot $(ON_SIMULATOR) build-for-testing $(BEAUTIFY)

test:
	@test -n "$(SIMULATOR)" || { echo "NG iPhone のシミュレーターが無い。SIMULATOR に UDID を渡す"; exit 1; }
	@mkdir -p .build
	set -o pipefail; $(XCODEBUILD) -testPlan Kakeibot $(ON_SIMULATOR) -collect-test-diagnostics never test 2>&1 $(BEAUTIFY) | tee .build/test.log

snapshot:
	@test -n "$(SNAPSHOT)" || { echo "NG SNAPSHOT に .claude/snapshots/ の下のセットの名前を渡す"; exit 1; }
	$(CLAUDE_CONFIG)/dotclaude/skills/ui-snapshot/scripts/render-snapshots.sh ios/Packages/KakeibotApp .claude/snapshots/$(SNAPSHOT) .build/snapshots/$(SNAPSHOT)

android-build:
	$(GRADLE) :app:assembleDebug

android-test:
	$(GRADLE) :core:test :store:test

verify: verify-docs
	scripts/verify.sh spacing-check python3 -I scripts/spacing-check.py
	@test -f $(CLAUDE_CONFIG)/dotclaude/hooks/swift-style-check.py || { echo "NG claude-config に swift-style-check が無い: $(CLAUDE_CONFIG)"; exit 1; }
	scripts/verify.sh swift-style python3 -I $(CLAUDE_CONFIG)/dotclaude/hooks/swift-style-check.py $$(git ls-files '*.swift')
	scripts/verify.sh kit-test swift test --package-path ios/Packages/KakeibotKit
	scripts/verify.sh app-build $(XCODEBUILD) $(ANY_SIMULATOR) build
	scripts/verify.sh android-test $(GRADLE) :core:test :store:test
	scripts/verify.sh android-build $(GRADLE) :app:assembleDebug

verify-docs:
	scripts/verify.sh docs-check scripts/docs-check.py
	scripts/verify.sh json-format scripts/json-format.sh check
	@test -f $(CLAUDE_CONFIG)/dotclaude/hooks/docs-check.py || { echo "NG claude-config が無い: $(CLAUDE_CONFIG)"; exit 1; }
	scripts/verify.sh docs-rules python3 -I $(CLAUDE_CONFIG)/dotclaude/hooks/docs-check.py $$(git ls-files '*.md')
