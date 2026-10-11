.PHONY: setup format build

setup:
	brew bundle
	mint bootstrap
	pre-commit install

format:
	mint run swiftformat .

build:
	xcodebuild -project ios/Kakeibot.xcodeproj -scheme Kakeibot -destination 'generic/platform=iOS Simulator' build
