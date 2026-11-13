import AVFoundation
import Foundation
import Speech

@available(iOS 26.0, *)
final class EntryVoiceAudioFeed: @unchecked Sendable {
    private let converter: AVAudioConverter
    private let format: AVAudioFormat
    private let continuation: AsyncStream<AnalyzerInput>.Continuation

    init(
        from inputFormat: AVAudioFormat,
        to format: AVAudioFormat,
        continuation: AsyncStream<AnalyzerInput>.Continuation
    ) throws {
        guard let converter = AVAudioConverter(from: inputFormat, to: format) else {
            throw FeedError.unconvertible
        }

        converter.primeMethod = .none

        self.converter = converter
        self.format = format
        self.continuation = continuation
    }

    func receive(_ buffer: AVAudioPCMBuffer) {
        if let converted = convert(buffer) {
            continuation.yield(AnalyzerInput(buffer: converted))
        }
    }

    func finish() {
        continuation.finish()
    }
}

@available(iOS 26.0, *)
private extension EntryVoiceAudioFeed {
    enum FeedError: Error {
        case unconvertible
    }

    func convert(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        let ratio = format.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount((Double(buffer.frameLength) * ratio).rounded(.up))

        guard let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: max(capacity, 1))
        else {
            return nil
        }

        var isSupplied = false
        var error: NSError?

        let status = converter.convert(to: output, error: &error) { _, inputStatus in
            if isSupplied {
                inputStatus.pointee = .noDataNow
                return nil
            }

            isSupplied = true
            inputStatus.pointee = .haveData
            return buffer
        }

        guard status != .error, output.frameLength > 0 else {
            return nil
        }

        return output
    }
}
