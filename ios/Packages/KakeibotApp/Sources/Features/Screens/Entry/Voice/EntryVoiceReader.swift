import AVFoundation
import Core
import Foundation
import Speech

enum EntryVoiceReader {
    static let locale = Locale(identifier: "ja-JP")

    static func isAvailable() async -> Bool {
        guard #available(iOS 26.0, *) else {
            return false
        }

        guard SpeechTranscriber.isAvailable else {
            return false
        }

        return await SpeechTranscriber.supportedLocale(equivalentTo: locale) != nil
    }

    static func isDenied() -> Bool {
        AVAudioApplication.shared.recordPermission == .denied
            || SFSpeechRecognizer.authorizationStatus() == .denied
            || SFSpeechRecognizer.authorizationStatus() == .restricted
    }

    static func requestPermission() async -> Bool {
        guard await AVAudioApplication.requestRecordPermission() else {
            return false
        }

        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization(resume(continuation))
        }

        return status == .authorized
    }

    @MainActor
    static func makeSource() -> (any EntryVoiceSource)? {
        guard #available(iOS 26.0, *) else {
            return nil
        }

        return EntryVoiceListener()
    }

    @MainActor
    static func prepare() {
        if #available(iOS 26.0, *) {
            EntryVoiceModel.prepare()
        }
    }

    @MainActor
    static func choose(_ question: EntryVoiceQuestion) async -> VoiceReading.Choice? {
        guard #available(iOS 26.0, *) else {
            return nil
        }

        return await EntryVoiceModel.choose(
            in: question.text,
            categories: question.categories,
            wallets: question.wallets,
            examples: question.examples
        )
    }
}

private extension EntryVoiceReader {
    static func resume(
        _ continuation: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>
    ) -> @Sendable (SFSpeechRecognizerAuthorizationStatus) -> Void {
        { status in
            continuation.resume(returning: status)
        }
    }
}
