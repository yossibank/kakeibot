import AVFoundation
import Foundation
import Speech

@available(iOS 26.0, *)
@MainActor
final class EntryVoiceListener: EntryVoiceSource {
    private let mic = EntryVoiceMic()

    private var analyzer: SpeechAnalyzer?
    private var resultsTask: Task<Void, Never>?

    func start(
        hints: [String],
        _ onEvent: @escaping @MainActor (EntryVoiceEvent) -> Void
    ) async throws {
        guard let locale = await SpeechTranscriber
            .supportedLocale(equivalentTo: EntryVoiceReader.locale) else {
            throw ListenError.unsupported
        }

        let transcriber = SpeechTranscriber(
            locale: locale,
            transcriptionOptions: [],
            reportingOptions: [.volatileResults, .alternativeTranscriptions],
            attributeOptions: []
        )

        if let request = try await AssetInventory
            .assetInstallationRequest(supporting: [transcriber]) {
            try await request.downloadAndInstall()
        }

        guard let format = await SpeechAnalyzer
            .bestAvailableAudioFormat(compatibleWith: [transcriber]) else {
            throw ListenError.unsupported
        }

        let analyzer = SpeechAnalyzer(modules: [transcriber])
        let context = AnalysisContext()

        context.contextualStrings[.general] = Array(hints.prefix(Self.maxHints))
        try? await analyzer.setContext(context)
        let (stream, continuation) = AsyncStream.makeStream(of: AnalyzerInput.self)

        self.analyzer = analyzer

        try await mic.start(
            to: format,
            continuation: continuation,
            onLevel: Self.report(to: onEvent)
        )

        try await analyzer.start(inputSequence: stream)

        resultsTask = Task { @MainActor in
            var transcript = EntryVoiceTranscript()
            var segments: [[String]] = []

            do {
                for try await result in transcriber.results {
                    let text = String(result.text.characters)

                    if result.isFinal {
                        let alternatives = result.alternatives
                            .map { String($0.characters) }
                            .filter { $0 != text }

                        segments.append([text] + alternatives)
                        transcript.settled += text
                        transcript.pending = ""
                        transcript.alternatives = Self.candidates(of: segments)
                    } else {
                        transcript.pending = text
                    }

                    onEvent(.transcript(transcript))
                }
            } catch {
                return
            }
        }
    }

    func finish() async {
        await mic.stop()

        try? await analyzer?.finalizeAndFinishThroughEndOfInput()

        if let resultsTask {
            await Self.wait(for: resultsTask, upTo: Self.finishTimeout)
        }

        clear()
    }

    func cancel() async {
        await mic.stop()
        resultsTask?.cancel()
        await analyzer?.cancelAndFinishNow()
        clear()
    }
}

@available(iOS 26.0, *)
private extension EntryVoiceListener {
    enum ListenError: Error {
        case unsupported
    }

    static let maxHints = 100
    static let maxCandidates = 8

    static let finishTimeout: Duration = .seconds(2)

    static func candidates(of segments: [[String]]) -> [String] {
        let primaries = segments.compactMap(\.first)
        var candidates: [String] = []

        for (index, segment) in segments.enumerated() {
            for alternative in segment.dropFirst() {
                var words = primaries
                words[index] = alternative
                candidates.append(words.joined())
            }
        }

        return Array(candidates.prefix(maxCandidates))
    }

    nonisolated static func report(
        to onEvent: @escaping @MainActor (EntryVoiceEvent) -> Void
    ) -> @Sendable (Double) -> Void {
        { level in
            Task { @MainActor in
                onEvent(.level(level))
            }
        }
    }

    static func wait(
        for task: Task<Void, Never>,
        upTo timeout: Duration
    ) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await task.value
            }

            group.addTask {
                try? await Task.sleep(for: timeout)
            }

            await group.next()
            group.cancelAll()
        }
    }

    func clear() {
        analyzer = nil
        resultsTask = nil
    }
}
