import AVFoundation
import Foundation
import Speech

@available(iOS 26.0, *)
final class EntryVoiceAudioFeed: @unchecked Sendable {
    private let converter: AVAudioConverter
    private let format: AVAudioFormat
    private let continuation: AsyncStream<AnalyzerInput>.Continuation
    private let onLevel: @Sendable (Double) -> Void
    private let levelFrames: Int

    private var squareSum: Float = 0
    private var measuredFrames = 0

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

        self.levelFrames = max(Int(inputFormat.sampleRate * Self.levelInterval), 1)
    }

    static func level(rms: Float) -> Double {
        guard rms > 0 else {
            return 0
        }

        let decibels = 20 * log10(Double(rms))
        let level = (decibels - quietDecibels) / (loudDecibels - quietDecibels)
        return min(max(level, 0), 1)
    }

    func receive(_ buffer: AVAudioPCMBuffer) {
        measure(buffer)

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

    static let levelInterval = 0.08
    static let quietDecibels = -55.0
    static let loudDecibels = -20.0

    func measure(_ buffer: AVAudioPCMBuffer) {
        guard let samples = buffer.floatChannelData?[0] else {
            return
        }

        let count = Int(buffer.frameLength)

        for index in 0..<count {
            squareSum += samples[index] * samples[index]
        }

        measuredFrames += count

        guard measuredFrames >= levelFrames else {
            return
        }

        let rms = (squareSum / Float(measuredFrames)).squareRoot()

        squareSum = 0
        measuredFrames = 0
        onLevel(Self.level(rms: rms))
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
