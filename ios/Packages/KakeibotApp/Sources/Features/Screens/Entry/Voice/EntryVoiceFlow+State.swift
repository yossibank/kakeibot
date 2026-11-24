import Core
import Foundation
import Observation

extension EntryVoiceFlow {
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

    @MainActor
    @Observable
    final class State {
        private(set) var step: Step?
        private(set) var silenceStart: Date?
        private(set) var startCount = 0
        private(set) var endCount = 0

        private(set) var notice: Notice?
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
        var isAvailable = false
        var transcript = EntryVoiceTranscript()
        var preview: VoiceReading?
        var levels = EntryVoiceFlow.quietLevels

        @ObservationIgnored var source: (any EntryVoiceSource)?
        @ObservationIgnored var session: Session?
        @ObservationIgnored var lastVoice: Date?
        @ObservationIgnored var silenceTask: Task<Void, Never>?
        @ObservationIgnored var noticeTask: Task<Void, Never>?
        @ObservationIgnored var isStarting = false

        let silenceDuration: TimeInterval

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

    struct Session {
        let model: EntryModel
        let today: LocalDate
        let onApplied: @MainActor () -> Void
    }
}

extension EntryVoiceFlow.Output {
    var isActive: Bool {
        state.step != nil
    }
}
