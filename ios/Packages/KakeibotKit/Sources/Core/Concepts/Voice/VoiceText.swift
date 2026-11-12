import Foundation

struct VoiceText {
    let text: String

    private let folded: [Character]
    private let characters: [Character]

    init(_ raw: String) {
        let text = Self.removingDigitCommas(raw.precomposedStringWithCompatibilityMapping)

        self.text = text
        self.characters = Array(text)
        self.folded = Array(Self.fold(text))
    }
}

extension VoiceText {
    struct Found<Value> {
        let value: Value
        let range: Range<String.Index>
    }

    func contains(_ name: String) -> Bool {
        range(of: name) != nil
    }

    func range(of name: String) -> Range<String.Index>? {
        let target = Array(Self.fold(name))

        guard
            !target.isEmpty,
            folded.count == characters.count,
            target.count <= folded.count
        else {
            return text.range(of: name)
        }

        for start in 0...(folded.count - target.count)
            where Array(folded[start..<start + target.count]) == target {
            let lower = text.index(text.startIndex, offsetBy: start)
            let upper = text.index(lower, offsetBy: target.count)
            return lower..<upper
        }

        return nil
    }

    func memo(removing ranges: [Range<String.Index>]) -> String? {
        var kept = ""
        var index = text.startIndex

        for range in ranges.sorted(by: { $0.lowerBound < $1.lowerBound })
            where range.lowerBound >= index {
            kept += text[index..<range.lowerBound]
            kept += " "
            index = range.upperBound
        }

        kept += text[index...]

        let fragments = kept
            .components(separatedBy: Self.separators)
            .filter { !Self.fillers.contains($0) && !Self.endings.contains($0) }
            .map(Self.trimmed)
            .filter { !$0.isEmpty && !Self.payments.contains($0) }

        return fragments.isEmpty ? nil : fragments.joined(separator: " ")
    }
}

private extension VoiceText {
    static let separators = CharacterSet.whitespacesAndNewlines
        .union(CharacterSet(charactersIn: "、。,.!?！？「」"))

    static let particles: Set<Character> = ["で", "に", "を", "は", "が", "と", "も", "の", "へ"]

    static let endings = [
        "の支払い",
        "支払い",
        "の料金",
        "の代金",
        "代金",
        "払いました",
        "払った",
        "買いました",
        "買った",
        "使いました",
        "使った",
        "でした",
        "です"
    ]

    static let payments: Set = ["現金", "クレカ", "クレジット", "クレジットカード", "カード払い", "電子マネー", "現金払い"]

    static let fillers: Set = ["えっと", "えーと", "えー", "あの", "あと", "それと", "から", "より"]

    static func fold(_ text: String) -> String {
        let katakana = text.applyingTransform(.hiraganaToKatakana, reverse: false) ?? text
        return katakana.lowercased()
    }

    static func removingDigitCommas(_ text: String) -> String {
        text.replacing(#/([0-9])[,，](?=[0-9]{3})/#) { "\($0.output.1)" }
    }

    static func trimmed(_ fragment: String) -> String {
        var word = fragment

        for ending in endings where word.hasSuffix(ending) && word.count > ending.count {
            word.removeLast(ending.count)
            break
        }

        if let first = word.first, particles.contains(first), word.count > 1 {
            word.removeFirst()
        }

        if let last = word.last, particles.contains(last), word.count > 1 {
            word.removeLast()
        }

        if word.count == 1, let only = word.first, particles.contains(only) {
            return ""
        }

        return word
    }
}
