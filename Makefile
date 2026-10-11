.PHONY: setup open format build test

SIMULATOR ?= $(shell xcrun simctl list devices available iPhone | awk -F '[()]' '/iPhone/ { print $$2; exit }')

setup:
	brew bundle
	mint bootstrap
	pre-commit install

open:
	open ios/Kakeibot.xcodeproj

format:
	mint run swiftformat .

build:
	xcodebuild -project ios/Kakeibot.xcodeproj -scheme Kakeibot -destination 'generic/platform=iOS Simulator' build

test:
	xcodebuild -project ios/Kakeibot.xcodeproj -scheme Kakeibot -testPlan Kakeibot -destination 'id=$(SIMULATOR)' test
