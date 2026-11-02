import Core
import CoreGraphics
import Foundation
import Vision

enum EntryReceiptReader {
    static func read(_ pages: [CGImage]) async -> ReceiptReading {
        var lines: [String] = []

        for page in pages {
            lines += await textLines(in: page)
        }

        let reading = ReceiptReading(lines: lines)

        guard
            !lines.isEmpty,
            #available(iOS 26.0, *),
            let guessed = await EntryReceiptModel.read(lines) else {
            return reading
        }

        return reading.merging(guessed)
    }
}

private extension EntryReceiptReader {
    static let languages = [
        Locale.Language(identifier: "ja-JP"),
        Locale.Language(identifier: "en-US")
    ]

    static func textLines(in image: CGImage) async -> [String] {
        var request = RecognizeTextRequest()

        request.recognitionLevel = .accurate
        request.recognitionLanguages = languages
        request.usesLanguageCorrection = true

        guard let observations = try? await request.perform(on: image) else {
            return []
        }

        let fragments = observations.compactMap { observation -> ReceiptFragment? in
            guard let text = observation.topCandidates(1).first?.string else {
                return nil
            }

            let box = observation.boundingBox.cgRect

            return ReceiptFragment(
                text: text,
                minX: box.minX,
                midY: 1 - box.midY,
                height: box.height
            )
        }

        return ReceiptFragment.lines(of: fragments)
    }
}
