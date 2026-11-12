import AVFoundation
import Foundation
import Speech

@available(iOS 26.0, *)
@MainActor
final class EntryVoiceListener: EntryVoiceSource {
    private let engine = AVAudioEngine()

    private var analyzer: SpeechAnalyzer?
    private var feed: EntryVoiceAudioFeed?
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

        try Self.activateSession()

        let analyzer = SpeechAnalyzer(modules: [transcriber])
        let context = AnalysisContext()

        context.contextualStrings[.general] = Array(hints.prefix(Self.maxHints))
        try? await analyzer.setContext(context)
        let (stream, continuation) = AsyncStream.makeStream(of: AnalyzerInput.self)
        let input = engine.inputNode
        let inputFormat = input.outputFormat(forBus: 0)

        let feed = try EntryVoiceAudioFeed(
            from: inputFormat,
            to: format,
            continuation: continuation,
            onLevel: Self.levelHandler(onEvent)
        )

        input.installTap(
            onBus: 0,
            bufferSize: Self.bufferSize,
            format: inputFormat,
            block: Self.tap(feed)
        )

        engine.prepare()
        try engine.start()
        try await analyzer.start(inputSequence: stream)

        self.analyzer = analyzer
        self.feed = feed

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
        stopAudio()

        try? await analyzer?.finalizeAndFinishThroughEndOfInput()

        if let resultsTask {
            await Self.wait(for: resultsTask, upTo: Self.finishTimeout)
        }

        clear()
    }

    func cancel() async {
        stopAudio()
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

    static let bufferSize: AVAudioFrameCount = 1024
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

    static func activateSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    nonisolated static func tap(_ feed: EntryVoiceAudioFeed) -> AVAudioNodeTapBlock {
        { buffer, _ in
            feed.receive(buffer)
        }
    }

    nonisolated static func levelHandler(
        _ onEvent: @escaping @MainActor (EntryVoiceEvent) -> Void
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

    func stopAudio() {
        if engine.isRunning {
            engine.stop()
        }

        engine.inputNode.removeTap(onBus: 0)
        feed?.finish()

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func clear() {
        analyzer = nil
        feed = nil
        resultsTask = nil
    }
}
