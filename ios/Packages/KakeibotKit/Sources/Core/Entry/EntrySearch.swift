import Foundation

public struct EntrySearch: Hashable, Sendable {
    public let words: [String]

    public init(_ text: String) {
        self.words = text
            .split(whereSeparator: \.isWhitespace)
            .map { Self.fold(String($0)) }
    }
}

public extension EntrySearch {
    var isEmpty: Bool {
        words.isEmpty
    }

    func matches(
        amount: Int,
        texts: [String]
    ) -> Bool {
        let folded = texts.map(Self.fold)

        return words.allSatisfy { word in
            if Self.amount(in: word) == amount {
                return true
            }

            return folded.contains { $0.contains(word) }
        }
    }
}

private extension EntrySearch {
    static let amountMarks: Set<Character> = ["¥", "\\", ",", "円"]

    static func fold(_ text: String) -> String {
        text.folding(
            options: [.caseInsensitive, .widthInsensitive],
            locale: Locale(identifier: "ja_JP")
        )
    }

    static func amount(in word: String) -> Int? {
        let digits = word.filter { !amountMarks.contains($0) }

        guard
            !digits.isEmpty,
            digits.allSatisfy(\.isASCII)
        else {
            return nil
        }

        return Int(digits)
    }
}
