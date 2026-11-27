import Core
@testable import FeatureModels
@testable import Features
import Foundation
import Store
import Testing

@MainActor
final class FakeVoiceSource: EntryVoiceSource {
    private(set) var isFinished = false
    private(set) var isCancelled = false
    private(set) var hints: [String] = []
    private(set) var log: [String] = []

    var holdsStart = false
    var finalTranscript: EntryVoiceTranscript?

    private var onEvent: (@MainActor (EntryVoiceEvent) -> Void)?
    private var startGate: CheckedContinuation<Void, Never>?

    var isHolding: Bool {
        startGate != nil
    }

    func start(
        hints: [String],
        _ onEvent: @escaping @MainActor (EntryVoiceEvent) -> Void
    ) async throws {
        self.hints = hints
        self.onEvent = onEvent

        if holdsStart {
            await withCheckedContinuation { continuation in
                startGate = continuation
            }
        }

        log.append("start")
    }

    func finish() async {
        if let finalTranscript {
            onEvent?(.transcript(finalTranscript))
        }

        isFinished = true
        log.append("finish")
    }

    func cancel() async {
        isCancelled = true
        log.append("cancel")
    }

    func releaseStart() {
        startGate?.resume()
        startGate = nil
    }

    func hear(_ level: Double) {
        onEvent?(.level(level))
    }

    func say(
        _ text: String,
        alternatives: [String] = []
    ) {
        onEvent?(.transcript(EntryVoiceTranscript(settled: text, alternatives: alternatives)))
    }
}

@MainActor
extension EntryVoiceFlow.Dependencies {
    static func fake(_ source: FakeVoiceSource) -> Self {
        Self(
            isAvailable: { true },
            isDenied: { false },
            requestPermission: { true },
            makeSource: { source },
            prepare: {},
            choose: { _ in nil },
            clock: .system,
            wait: .system,
            sleep: { duration in
                try await Task.sleep(for: duration)
            },
            silence: .milliseconds(100)
        )
    }

    static func fake(
        _ source: FakeVoiceSource,
        wait: ManualWait
    ) -> Self {
        var dependencies = fake(source)
        dependencies.wait = wait.wait
        return dependencies
    }

    static func fake(
        _ source: FakeVoiceSource,
        clock: FakeVoiceClock
    ) -> Self {
        var dependencies = fake(source)
        dependencies.clock = clock.screenClock

        dependencies.sleep = { duration in
            try await clock.sleep(for: duration)
        }

        return dependencies
    }
}
