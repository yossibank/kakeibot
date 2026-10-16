.PHONY: setup open format build test

SIMULATOR ?= $(shell xcrun simctl list devices available iPhone | awk -F '[()]' '/iPhone/ { print $$2; exit }')
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

build:
	xcodebuild -workspace ios/Kakeibot.xcworkspace -scheme Kakeibot -destination 'generic/platform=iOS Simulator' build

test:
	xcodebuild -workspace ios/Kakeibot.xcworkspace -scheme Kakeibot -testPlan Kakeibot -destination 'id=$(SIMULATOR)' test
