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
        var step: Step?
        var silenceStart: Date?
        var startCount = 0
        var endCount = 0

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
