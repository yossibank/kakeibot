import Core
import Foundation
import Observation

public extension EntryVoiceFlow {
    struct Notice: Equatable, Identifiable {
        public let id = UUID()

        let outcome: Outcome
        let count: Int
        let text: String
        let undo: EntryModel.VoiceUndo?
    }

    @MainActor
    struct Notices {
        public let result: UndoNotice<Notice>

        init(wait: ScreenWait) {
            self.result = UndoNotice(wait: wait)
        }
    }

    struct Presented: Equatable, Sendable {
        public internal(set) var step: EntryVoiceFlow.Step?
    }

    @MainActor
    @Observable
    final class State {
        public internal(set) var presented = Presented()

        public let notices: Notices

        public private(set) var silence = Silence()
        public private(set) var rounds = Rounds()

        init(wait: ScreenWait) {
            self.notices = Notices(wait: wait)
        }
    }

    @MainActor
    @Observable
    final class Input {
        public internal(set) var isAvailable = false
        public internal(set) var transcript = EntryVoiceTranscript()
        public internal(set) var preview: VoiceReading?
        public internal(set) var levels = EntryVoiceFlow.quietLevels

        public let silenceDuration: TimeInterval

        @ObservationIgnored var source: (any EntryVoiceSource)?
        @ObservationIgnored var session: Session?
        @ObservationIgnored var lastVoice: Date?
        @ObservationIgnored var silenceTask: Task<Void, Never>?
        @ObservationIgnored var isStarting = false

        init(silenceDuration: TimeInterval) {
            self.silenceDuration = silenceDuration
        }
    }

    @MainActor
    final class Output {
        let input: Input
        let state: State

        init(
            input: Input,
            state: State
        ) {
            self.input = input
            self.state = state
        }
    }

    internal struct Session {
        let model: EntryModel
        let today: LocalDate
        let onApplied: @MainActor () -> Void
    }
}

extension EntryVoiceFlow.State {
    func setDenied(_ isDenied: Bool) {
        presented.step = isDenied ? .denied : nil
    }

    func closeDenied() {
        if presented.step == .denied {
            presented.step = nil
        }
    }

    func startListening() {
        presented.step = .listening
        rounds.start()
    }

    func startSilence(at date: Date) {
        silence.start(at: date)
    }

    func clearSilence() {
        silence.clear()
    }

    func finish() {
        silence.clear()
        presented.step = .reading
        rounds.end()
    }

    func countEnd() {
        rounds.end()
    }

    func reset() {
        silence.clear()
        presented.step = nil
    }
}

public extension EntryVoiceFlow.Notice {
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

public extension EntryVoiceFlow.Output {
    var isActive: Bool {
        state.presented.step != nil
    }
}
