import Core
import Foundation
import Observation

public extension EntryVoiceFlow {
    struct Notice: Equatable, Identifiable {
        public let id = UUID()

        let outcome: Outcome
        let count: Int
        let text: String

        public var title: String {
            switch outcome {
            case .applied: "声から \(count) つ入れました"
            case .missingAmount: "金額が聞き取れませんでした"
            case .unheard: text.isEmpty ? "聞き取れませんでした" : "入れられる項目がありませんでした"
            }
        }

        public var message: String? {
            text.isEmpty ? nil : "「\(text)」"
        }

        public var hint: String? {
            outcome == .applied ? nil : "もう一度「声」を押して話すか、テンキーで入れてください"
        }

        public var canUndo: Bool {
            outcome == .applied
        }
    }

    @MainActor
    @Observable
    final class State {
        public private(set) var step: Step?
        public private(set) var silenceStart: Date?
        public private(set) var startCount = 0
        public private(set) var endCount = 0

        public private(set) var notice: Notice?

        private(set) var undo: EntryModel.VoiceUndo?

        func show(
            _ notice: Notice,
            undo: EntryModel.VoiceUndo?
        ) {
            self.notice = notice
            self.undo = undo
        }

        func clearNotice() {
            notice = nil
            undo = nil
        }

        func setDenied(_ isDenied: Bool) {
            step = isDenied ? .denied : nil
        }

        func closeDenied() {
            if step == .denied {
                step = nil
            }
        }

        func startListening() {
            step = .listening
            startCount += 1
        }

        func startSilence(at date: Date) {
            silenceStart = date
        }

        func clearSilence() {
            silenceStart = nil
        }

        func finish() {
            silenceStart = nil
            step = .reading
            endCount += 1
        }

        func countEnd() {
            endCount += 1
        }

        func reset() {
            silenceStart = nil
            step = nil
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
        @ObservationIgnored var noticeTask: Task<Void, Never>?
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

public extension EntryVoiceFlow.Output {
    var isActive: Bool {
        state.step != nil
    }
}
