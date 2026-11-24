import AVFoundation
import Foundation
import Speech

@available(iOS 26.0, *)
actor EntryVoiceMic {
    private let engine = AVAudioEngine()

    private var feed: EntryVoiceAudioFeed?

    func start(
        to format: AVAudioFormat,
        continuation: AsyncStream<AnalyzerInput>.Continuation,
        onLevel: @escaping @Sendable (Double) -> Void
    ) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let input = engine.inputNode
        let inputFormat = input.outputFormat(forBus: 0)

        let feed = try EntryVoiceAudioFeed(
            from: inputFormat,
            to: format,
            continuation: continuation,
            onLevel: onLevel
        )

        self.feed = feed

        input.installTap(
            onBus: 0,
            bufferSize: Self.bufferSize,
            format: inputFormat,
            block: Self.tap(feed)
        )

        engine.prepare()
        try engine.start()
    }

    func stop() {
        if engine.isRunning {
            engine.stop()
        }

        engine.inputNode.removeTap(onBus: 0)
        feed?.finish()
        feed = nil

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

@available(iOS 26.0, *)
private extension EntryVoiceMic {
    static let bufferSize: AVAudioFrameCount = 1024

    static func tap(_ feed: EntryVoiceAudioFeed) -> AVAudioNodeTapBlock {
        { buffer, _ in
            feed.receive(buffer)
        }
    }
}
