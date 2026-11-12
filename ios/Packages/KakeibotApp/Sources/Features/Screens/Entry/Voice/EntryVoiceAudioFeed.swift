import AVFoundation
import Foundation
import Speech

@available(iOS 26.0, *)
final class EntryVoiceAudioFeed: @unchecked Sendable {
    private let converter: AVAudioConverter
    private let format: AVAudioFormat
    private let continuation: AsyncStream<AnalyzerInput>.Continuation
    private let onLevel: @Sendable (Double) -> Void

    init(
        from inputFormat: AVAudioFormat,
        to format: AVAudioFormat,
        continuation: AsyncStream<AnalyzerInput>.Continuation,
        onLevel: @escaping @Sendable (Double) -> Void
    ) throws {
        guard let converter = AVAudioConverter(from: inputFormat, to: format) else {
            throw FeedError.unconvertible
        }

        converter.primeMethod = .none

        self.converter = converter
        self.format = format
        self.continuation = continuation
        self.onLevel = onLevel
    }

    func receive(_ buffer: AVAudioPCMBuffer) {
        onLevel(Self.level(of: buffer))

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

    static let quietDecibels: Float = -55
    static let loudDecibels: Float = -15

    static func level(of buffer: AVAudioPCMBuffer) -> Double {
        guard
            let samples = buffer.floatChannelData?[0],
            buffer.frameLength > 0
        else {
            return 0
        }

        let count = Int(buffer.frameLength)
        var sum: Float = 0

        for index in 0..<count {
            sum += samples[index] * samples[index]
        }

        let rms = (sum / Float(count)).squareRoot()
        let decibels = 20 * log10(max(rms, .leastNonzeroMagnitude))
        let ratio = (decibels - quietDecibels) / (loudDecibels - quietDecibels)

        return Double(min(max(ratio, 0), 1))
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
