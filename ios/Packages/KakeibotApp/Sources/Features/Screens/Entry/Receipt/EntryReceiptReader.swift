import Core
import CoreGraphics
import Foundation
import Vision

enum EntryReceiptReader {
    static func read(_ pages: [CGImage]) async -> ReceiptReading {
        var pageLines: [[String]] = []

        for page in pages {
            await pageLines.append(textLines(in: page))
        }

        let lines = pageLines.flatMap(\.self)
        let reading = ReceiptReading(lines: lines)
        let settled = reading.settlingTax()

        guard
            !lines.isEmpty,
            !settled.isSettled,
            #available(iOS 26.0, *),
            let guessed = await EntryReceiptModel.read(pages: pageLines, rules: reading)
        else {
            return settled
        }

        return reading.merging(guessed)
    }

    @MainActor
    static func prepare() {
        if #available(iOS 26.0, *) {
            EntryReceiptModel.prepare()
        }
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
                height: box.height,
                maxX: box.maxX,
                tilt: tilt(of: observation)
            )
        }

        return ReceiptFragment.lines(of: fragments)
    }

    static func tilt(of observation: RecognizedTextObservation) -> Double {
        let width = observation.topRight.x - observation.topLeft.x

        guard width > 0 else {
            return 0
        }

        return (observation.topLeft.y - observation.topRight.y) / width
    }
}
