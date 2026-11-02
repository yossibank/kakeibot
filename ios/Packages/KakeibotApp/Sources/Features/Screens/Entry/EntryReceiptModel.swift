import Core
import Foundation
import FoundationModels

@available(iOS 26.0, *)
enum EntryReceiptModel {
    static func read(_ lines: [String]) async -> ReceiptReading? {
        let model = SystemLanguageModel.default

        guard
            model.isAvailable,
            model.supportsLocale(Self.locale)
        else {
            return nil
        }

        let session = LanguageModelSession(
            model: model,
            instructions: Self.instructions
        )

        do {
            let response = try await session.respond(
                to: lines.joined(separator: "\n"),
                generating: Guess.self
            )

            return response.content.reading
        } catch {
            return nil
        }
    }
}

@available(iOS 26.0, *)
private extension EntryReceiptModel {
    @Generable
    struct Guess {
        @Guide(description: "レシートの上にある店名。読めなければ空")
        var store: String

        @Guide(description: "買った日。yyyy-MM-dd の形。読めなければ空")
        var date: String

        @Guide(description: "支払う合計の金額。円の整数。読めなければ 0")
        var total: Int

        @Guide(description: "買った品目。上から順に並べる")
        var items: [Item]
    }

    @Generable
    struct Item {
        @Guide(description: "品名。数量や単価の文字は入れない")
        var name: String

        @Guide(description: "数量。書いていなければ 1")
        var quantity: Int

        @Guide(description: "数量を掛け、値引を引いた後の金額。円の整数")
        var amount: Int
    }

    static let locale = Locale(identifier: "ja_JP")

    static let instructions = """
    日本のレシートを文字認識した行から、店名・日付・合計・品目を取り出す。
    小計・税・合計・お預り・お釣・ポイントの行は品目にしない。
    数量の行と値引の行は、前の品目の数量と金額にまとめる。
    行に無い値を作らない。
    """
}

@available(iOS 26.0, *)
private extension EntryReceiptModel.Guess {
    var reading: ReceiptReading {
        let store = store.trimmingCharacters(in: .whitespacesAndNewlines)

        let items = items
            .filter {
                !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.amount != 0
            }
            .map {
                EntryItem.Draft(
                    name: $0.name.trimmingCharacters(in: .whitespacesAndNewlines),
                    quantity: max($0.quantity, 1),
                    amount: $0.amount
                )
            }

        return ReceiptReading(
            store: store.isEmpty ? nil : store,
            date: LocalDate(date),
            total: total > 0 ? total : nil,
            items: items
        )
    }
}
