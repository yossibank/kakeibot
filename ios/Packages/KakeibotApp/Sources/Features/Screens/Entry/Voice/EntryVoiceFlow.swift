import Core
import Foundation
import Observation

@MainActor
@Observable
final class EntryVoiceFlow {
    private(set) var isAvailable = false
    private(set) var step: Step?
    private(set) var transcript = EntryVoiceTranscript()
    private(set) var preview: VoiceReading?
    private(set) var notice: Notice?
    private(set) var startCount = 0
    private(set) var endCount = 0

    @ObservationIgnored private var source: (any EntryVoiceSource)?
    @ObservationIgnored private var silenceTask: Task<Void, Never>?
    @ObservationIgnored private var noticeTask: Task<Void, Never>?
    @ObservationIgnored private var session: Session?
    @ObservationIgnored private var undo: EntryModel.VoiceUndo?
    @ObservationIgnored private var isStarting = false

    private let dependencies: Dependencies

    init(dependencies: Dependencies = .live) {
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

    struct Notice: Equatable, Identifiable {
        let id = UUID()
        let outcome: Outcome
        let count: Int
        let text: String

        var title: String {
            switch outcome {
            case .applied: "声から \(count) つ入れました"
            case .missingAmount: "金額が聞き取れませんでした"
            case .unheard: text.isEmpty ? "聞き取れませんでした" : "入れられる項目がありませんでした"
            }
        }

        var message: String? {
            text.isEmpty ? nil : "「\(text)」"
        }

        var hint: String? {
            outcome == .applied ? nil : "もう一度「声」を押して話すか、テンキーで入れてください"
        }

        var canUndo: Bool {
            outcome == .applied
        }
    }

    struct Dependencies {
        static var live: Dependencies {
            Dependencies(
                isAvailable: EntryVoiceReader.isAvailable,
                isDenied: EntryVoiceReader.isDenied,
                requestPermission: EntryVoiceReader.requestPermission,
                makeSource: EntryVoiceReader.makeSource,
                prepare: EntryVoiceReader.prepare,
                choose: EntryVoiceReader.choose,
                silence: .milliseconds(1500),
                noticeDuration: .seconds(4)
            )
        }

        var isAvailable: () async -> Bool
        var isDenied: () -> Bool
        var requestPermission: () async -> Bool
        var makeSource: @MainActor () -> (any EntryVoiceSource)?
        var prepare: @MainActor () -> Void
        var choose: @MainActor (EntryVoiceQuestion) async -> VoiceReading.Choice?
        var silence: Duration
        var noticeDuration: Duration
    }

    static let failedMessage = "声を聞き取れませんでした。もう一度押してください"

    var isActive: Bool {
        step != nil
    }

    func checkAvailability() async {
        isAvailable = await dependencies.isAvailable()
    }

    func start(
        for model: EntryModel,
        today: LocalDate,
        onApplied: @escaping @MainActor () -> Void
    ) async {
        guard step == nil, !isStarting else {
            return
        }

        isStarting = true

        defer {
            isStarting = false
        }

        clearNotice()

        guard await dependencies.requestPermission() else {
            step = dependencies.isDenied() ? .denied : nil
            return
        }

        guard let source = dependencies.makeSource() else {
            return
        }

        dependencies.prepare()

        self.source = source
        session = Session(model: model, today: today, onApplied: onApplied)
        transcript = EntryVoiceTranscript()
        preview = nil
        step = .listening
        startCount += 1

        do {
            try await source.start(hints: model.voiceHints) { [weak self] event in
                self?.receive(event)
            }
        } catch {
            await source.cancel()

            guard self.source === source else {
                return
            }

            reset()
            endCount += 1
            model.errorNotice.show(Self.failedMessage)
            return
        }

        if self.source !== source || step != .listening {
            await source.cancel()
        }
    }

    func finish() async {
        guard step == .listening, let source, let session else {
            return
        }

        silenceTask?.cancel()
        step = .reading
        endCount += 1

        await source.finish()

        await read(transcript, in: session)
        reset()
    }

    func cancel() async {
        guard let source else {
            step = nil
            return
        }

        silenceTask?.cancel()
        endCount += 1
        await source.cancel()
        reset()
    }

    func closeDenied() {
        if step == .denied {
            step = nil
        }
    }

    func undoLast(in model: EntryModel) {
        if let undo {
            model.undo(undo)
        }

        clearNotice()
    }

    func clearNotice() {
        noticeTask?.cancel()
        notice = nil
        undo = nil
    }
}

private extension EntryVoiceFlow {
    struct Session {
        let model: EntryModel
        let today: LocalDate
        let onApplied: @MainActor () -> Void
    }

    static func spokenText(
        of transcript: EntryVoiceTranscript,
        in session: Session
    ) -> String {
        let primary = transcript.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidates = [primary] + transcript.alternatives

        let withAmount = candidates.first { candidate in
            session.model.voiceReading(from: candidate, today: session.today, choice: nil)
                .amount != nil
        }

        return withAmount ?? primary
    }

    func receive(_ event: EntryVoiceEvent) {
        if step == .reading, case let .transcript(transcript) = event {
            self.transcript = transcript
            return
        }

        guard step == .listening else {
            return
        }

        switch event {
        case let .transcript(transcript):
            self.transcript = transcript

            if let session {
                preview = session.model.voiceReading(
                    from: transcript.text,
                    today: session.today,
                    choice: nil
                )
            }

            if !transcript.isEmpty {
                waitForSilence()
            }
        }
    }

    func waitForSilence() {
        silenceTask?.cancel()

        let silence = dependencies.silence

        silenceTask = Task { [weak self] in
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
            categories: model.categories.map(\.name),
            wallets: model.wallets.map(\.name),
            examples: model.voiceExamples(for: text)
        )

        let choice = await dependencies.choose(question)
        let reading = model.voiceReading(from: text, today: session.today, choice: choice)

        guard !reading.isEmpty else {
            show(Notice(outcome: .unheard, count: 0, text: text))
            return
        }

        let undo = model.apply(reading)

        guard reading.amount != nil else {
            show(Notice(outcome: .missingAmount, count: reading.count, text: text))
            return
        }

        show(Notice(outcome: .applied, count: reading.count, text: text))
        self.undo = undo
        session.onApplied()
    }

    func show(_ notice: Notice) {
        noticeTask?.cancel()
        self.notice = notice

        let duration = dependencies.noticeDuration
        let id = notice.id

        noticeTask = Task { [weak self] in
            try? await Task.sleep(for: duration)

            guard !Task.isCancelled, self?.notice?.id == id else {
                return
            }

            self?.notice = nil
            self?.undo = nil
        }
    }

    func reset() {
        silenceTask?.cancel()
        silenceTask = nil
        source = nil
        session = nil
        step = nil
        preview = nil
    }
}
