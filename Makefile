.PHONY: setup open format build test

SIMULATOR ?= $(shell xcrun simctl list devices available iPhone | awk -F '[()]' '/iPhone/ { print $$2; exit }')

setup:
	brew bundle
	mint bootstrap
	pre-commit install

open:
	open ios/Kakeibot.xcworkspace

format:
	mint run swiftformat .

build:
	xcodebuild -workspace ios/Kakeibot.xcworkspace -scheme Kakeibot -destination 'generic/platform=iOS Simulator' build

test:
	xcodebuild -workspace ios/Kakeibot.xcworkspace -scheme Kakeibot -testPlan Kakeibot -destination 'id=$(SIMULATOR)' test
