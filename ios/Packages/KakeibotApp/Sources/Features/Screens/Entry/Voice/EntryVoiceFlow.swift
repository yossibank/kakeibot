import Core
import Foundation
import Observation

@MainActor
@Observable
final class EntryVoiceFlow {
    let state: State
    let input: Input
    let output: Output
    let dependencies: Dependencies

    init(dependencies: Dependencies) {
        let state = State()
        let input = Input(silenceDuration: dependencies.silence / .seconds(1))

        self.state = state
        self.input = input
        self.output = Output(input: input, state: state)
        self.dependencies = dependencies
    }
}

extension EntryVoiceFlow {
    enum Step: Hashable {
        case listening
        case reading
        case denied
    }

    enum Outcome: Equatable {
        case applied
        case missingAmount
        case unheard
    }

    struct Dependencies {
        var isAvailable: () async -> Bool
        var isDenied: () -> Bool
        var requestPermission: () async -> Bool
        var makeSource: @MainActor () -> (any EntryVoiceSource)?
        var prepare: @MainActor () -> Void
        var choose: @MainActor (EntryVoiceQuestion) async -> VoiceReading.Choice?
        var clock: ScreenClock
        var silence: Duration
        var noticeDuration: Duration

        static func live(clock: ScreenClock) -> Dependencies {
            Dependencies(
                isAvailable: EntryVoiceReader.isAvailable,
                isDenied: EntryVoiceReader.isDenied,
                requestPermission: EntryVoiceReader.requestPermission,
                makeSource: EntryVoiceReader.makeSource,
                prepare: EntryVoiceReader.prepare,
                choose: EntryVoiceReader.choose,
                clock: clock,
                silence: .seconds(1),
                noticeDuration: .seconds(4)
            )
        }
    }

    static let failedMessage = "声を聞き取れませんでした。もう一度押してください"
    static let levelCount = 16
    static let quietLevels = [Double](repeating: 0, count: levelCount)

    func checkAvailability() async {
        input.isAvailable = await dependencies.isAvailable()
    }

    func start(
        for model: EntryModel,
        today: LocalDate,
        onApplied: @escaping @MainActor () -> Void
    ) async {
        guard state.step == nil, !input.isStarting else {
            return
        }

        input.isStarting = true

        defer {
            input.isStarting = false
        }

        clearNotice()

        guard await dependencies.requestPermission() else {
            state.setDenied(dependencies.isDenied())
            return
        }

        guard let source = dependencies.makeSource() else {
            return
        }

        input.source = source
        input.session = Session(model: model, today: today, onApplied: onApplied)
        input.transcript = EntryVoiceTranscript()
        input.preview = nil
        state.startListening()

        do {
            try await source.start(hints: model.output.voiceHints) { [weak self] event in
                self?.receive(event)
            }
        } catch {
            await source.cancel()

            guard input.source === source else {
                return
            }

            reset()
            state.countEnd()
            model.state.errorNotice.show(Self.failedMessage)
            return
        }

        guard input.source === source, state.step == .listening else {
            await source.cancel()
            return
        }

        dependencies.prepare()
    }

    func finish() async {
        guard state.step == .listening, let source = input.source,
              let session = input.session else {
            return
        }

        input.silenceTask?.cancel()
        input.levels = Self.quietLevels
        state.finish()

        await source.finish()

        await read(input.transcript, in: session)
        reset()
    }

    func cancel() async {
        guard let source = input.source else {
            state.reset()
            return
        }

        input.silenceTask?.cancel()
        state.countEnd()
        await source.cancel()
        reset()
    }

    func closeDenied() {
        state.closeDenied()
    }

    func undoLast(in model: EntryModel) {
        if let undo = state.undo {
            model.undo(undo)
        }

        clearNotice()
    }

    func clearNotice() {
        input.noticeTask?.cancel()
        state.clearNotice()
    }
}

private extension EntryVoiceFlow {
    static let voiceLevel = 0.2

    static func spokenText(
        of transcript: EntryVoiceTranscript,
        in session: Session
    ) -> String {
        let primary = transcript.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidates = [primary] + transcript.alternatives

        let withAmount = candidates.first { candidate in
            session.model.output.voiceReading(from: candidate, today: session.today, choice: nil)
                .amount != nil
        }

        return withAmount ?? primary
    }

    func receive(_ event: EntryVoiceEvent) {
        if state.step == .reading, case let .transcript(transcript) = event {
            input.transcript = transcript
            return
        }

        guard state.step == .listening else {
            return
        }

        switch event {
        case let .transcript(transcript):
            input.transcript = transcript

            if let session = input.session {
                input.preview = session.model.output.voiceReading(
                    from: transcript.text,
                    today: session.today,
                    choice: nil
                )
            }

            if !transcript.isEmpty, input.lastVoice == nil {
                waitForSilence()
            }

        case let .level(level):
            input.levels = [level] + input.levels.dropLast()
            follow(level)
        }
    }

    func follow(_ level: Double) {
        guard level < Self.voiceLevel else {
            input.lastVoice = dependencies.clock.now
            input.silenceTask?.cancel()
            input.silenceTask = nil
            state.clearSilence()
            return
        }

        if input.lastVoice != nil {
            waitForSilence()
        }
    }

    func waitForSilence() {
        guard input.silenceTask == nil else {
            return
        }

        let silence = dependencies.silence
        state.startSilence(at: dependencies.clock.now)

        input.silenceTask = Task { [weak self] in
            try? await Task.sleep(for: silence)

            guard !Task.isCancelled else {
                return
            }

            await self?.finish()
        }
    }

    func read(
        _ transcript: EntryVoiceTranscript,
        in session: Session
    ) async {
        let model = session.model
        let text = Self.spokenText(of: transcript, in: session)

        guard !text.isEmpty else {
            show(Notice(outcome: .unheard, count: 0, text: ""))
            return
        }

        let question = EntryVoiceQuestion(
            text: text,
            categories: model.output.categories.map(\.name),
            wallets: model.output.wallets.map(\.name),
            examples: model.output.voiceExamples(for: text)
        )

        let choice = await dependencies.choose(question)
        let reading = model.output.voiceReading(from: text, today: session.today, choice: choice)

        guard !reading.isEmpty else {
            show(Notice(outcome: .unheard, count: 0, text: text))
            return
        }

        let undo = model.apply(reading)

        guard reading.amount != nil else {
            show(Notice(outcome: .missingAmount, count: reading.count, text: text))
            return
        }

        show(Notice(outcome: .applied, count: reading.count, text: text), undo: undo)
        session.onApplied()
    }

    func show(
        _ notice: Notice,
        undo: EntryModel.VoiceUndo? = nil
    ) {
        input.noticeTask?.cancel()
        state.show(notice, undo: undo)

        let duration = dependencies.noticeDuration
        let id = notice.id

        input.noticeTask = Task { [weak self] in
            try? await Task.sleep(for: duration)

            guard !Task.isCancelled, self?.state.notice?.id == id else {
                return
            }

            self?.state.clearNotice()
        }
    }

    func reset() {
        input.silenceTask?.cancel()
        input.silenceTask = nil
        input.lastVoice = nil
        input.levels = Self.quietLevels
        input.source = nil
        input.session = nil
        state.reset()
        input.preview = nil
    }
}
