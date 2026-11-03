import Core
import Foundation
import FoundationModels

@available(iOS 26.0, *)
@MainActor
enum EntryReceiptModel {
    private static var prepared: LanguageModelSession?

    static func prepare() {
        guard
            prepared == nil,
            isUsable
        else {
            return
        }

        let session = makeSession()
        session.prewarm()
        prepared = session
    }

    static func read(
        pages: [[String]],
        rules: ReceiptReading
    ) async -> ReceiptReading? {
        guard isUsable else {
            return nil
        }

        let lines = pages.flatMap(\.self)
        let session = prepared ?? makeSession()
        prepared = nil

        do {
            let labels = try await labels(of: lines, from: 0, in: session)
            let reading = ReceiptReading(lines: lines, labels: labels).settlingTax()

            guard needsReview(reading, rules: rules) else {
                return reading
            }

            return await reviewed(reading, lines: lines, in: session)
        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            return await readByPage(pages)
        } catch {
            return nil
        }
    }
}

@available(iOS 26.0, *)
private extension EntryReceiptModel {
    @Generable
    struct Guess {
        @Guide(description: "品名と金額が同じ行か次の行か、品目がどの行で終わるかを、行の番号を挙げて一文で書く")
        var layout: String

        @Guide(description: "店名が書かれた行の番号。無ければ -1")
        var storeLine: Int

        @Guide(description: "買った日付が書かれた行の番号。無ければ -1")
        var dateLine: Int

        @Guide(description: "支払う合計の金額の行の番号。小計・お預り・お釣の行ではない。無ければ -1")
        var totalLine: Int

        @Guide(description: "買った品目。上から順に並べる")
        var items: [Item]

        @Guide(description: "どの品目にも付かない、レシート全体の値引・割引・優待の行の番号")
        var discountLines: [Int]
    }

    @Generable
    struct Item {
        @Guide(description: "品目の金額が書かれた行の番号")
        var line: Int

        @Guide(description: "品名が金額と別の行にあるときの、品名の行の番号。同じ行なら -1")
        var nameLine: Int

        @Guide(description: "この品目の数量や単価が書かれた行の番号。無ければ -1")
        var quantityLine: Int

        @Guide(description: "この品目だけの値引・割引の行の番号")
        var discountLines: [Int]

        @Guide(description: "税率。軽減税率の印（※・軽・*）か 8% 対象の欄なら 8、10% 対象の欄なら 10、分からなければ 0")
        var taxRate: Int
    }

    static let locale = Locale(identifier: "ja_JP")

    static let options = GenerationOptions(sampling: .greedy)

    static let instructions = """
    日本のレシートを文字認識した行が「番号: 文字」の形で並ぶ。人がこのレシートを見て家計簿に書く内容を、行の番号で答える。
    まず layout に並び方を書き、それに沿って答える。品名や金額は書き写さず、行の番号だけを答える。行に無い番号は答えない。
    品目は、買った品物とその金額の行だけ。迷う行は品目にしない。
    品目にしない行：店名・住所・電話・登録番号・日時・番号だけの行、小計・お買上高・税・対象額・合計、お預り・お釣・カードの明細・残高・ポイント・案内の文。
    合計の行より後に品目は無い。
    金額だけの行や「外 27,200 1点 27,200」のような行は、上の行の品名を nameLine にする。
    「2コ×単198」「1 @780」のような数量の行は quantityLine に、品目の直後の値引の行はその品目の discountLines にする。
    小計の後の値引・割引・優待・歩引の行は、品目に付けず discountLines にする。
    税率は、※・軽・* の印か、※ の付いた番号の行の後の品目なら 8。「10%対象」の欄しか無いレシートは 10。それ以外は 0。

    例1
    0: スーパー青葉
    1: 2026年10月03日
    2: 牛乳 ※ ¥198
    3:   2コ×単198
    4: 洗剤 ¥398
    5: 値引 -30
    6: 合計 ¥650
    7: お預り ¥1,000
    答え：品名と金額が同じ行で、品目は 2〜5、6 が合計。店名 0、日付 1、合計 6。品目は 2（数量 3、税率 8）と 4（値引 5、税率 0）。

    例2
    0: Takashimaya
    1: 2026年10月30日
    2: h3287-2938※
    3: 揚物惣菜
    4: 602 602
    5: お買上高 602
    6: 歩引額 -60
    7: クレジット合計 585
    8: ご利用後残高 29,446
    答え：品名の次の行に金額で、品目は 3〜4、7 が合計。店名 0、日付 1、合計 7。品目は 4（品名 3、税率 8）。全体の値引は 6。
    """

    static var isUsable: Bool {
        let model = SystemLanguageModel.default
        return model.isAvailable && model.supportsLocale(locale)
    }

    static func makeSession() -> LanguageModelSession {
        LanguageModelSession(
            model: .default,
            instructions: instructions
        )
    }

    static func labels(
        of lines: [String],
        from start: Int,
        in session: LanguageModelSession
    ) async throws -> ReceiptLabels {
        let numbered = lines.enumerated().map { offset, text in
            "\(start + offset): \(text)"
        }

        let response = try await session.respond(
            to: numbered.joined(separator: "\n"),
            generating: Guess.self,
            options: options
        )

        return response.content.labels
    }

    static func readByPage(_ pages: [[String]]) async -> ReceiptReading? {
        guard pages.count > 1 else {
            return nil
        }

        var labels = ReceiptLabels()
        var start = 0

        for page in pages {
            guard let pageLabels = try? await Self.labels(of: page, from: start, in: makeSession())
            else {
                return nil
            }

            labels = labels.appending(pageLabels)
            start += page.count
        }

        return ReceiptReading(lines: pages.flatMap(\.self), labels: labels).settlingTax()
    }

    static func needsReview(
        _ reading: ReceiptReading,
        rules: ReceiptReading
    ) -> Bool {
        guard let difference = reading.difference else {
            return false
        }

        return difference != 0 && rules.difference != 0
    }

    static func reviewed(
        _ reading: ReceiptReading,
        lines: [String],
        in session: LanguageModelSession
    ) async -> ReceiptReading {
        guard
            let total = reading.total,
            let difference = reading.difference
        else {
            return reading
        }

        let prompt = """
        答えた行から金額を読むと、品目の合計は \(reading.itemTotal) 円で、合計の \(total) 円と \(abs(difference)) 円ずれている。
        品目・品名・数量・品目の値引・全体の値引・合計の行と税率を見直して、もう一度すべて答える。
        """

        guard
            let response = try? await session.respond(
                to: prompt,
                generating: Guess.self,
                options: options
            )
        else {
            return reading
        }

        let second = ReceiptReading(lines: lines, labels: response.content.labels).settlingTax()

        return abs(second.difference ?? .max) < abs(difference) ? second : reading
    }
}

@available(iOS 26.0, *)
private extension EntryReceiptModel.Guess {
    var labels: ReceiptLabels {
        ReceiptLabels(
            storeLine: Self.line(storeLine),
            dateLine: Self.line(dateLine),
            totalLine: Self.line(totalLine),
            items: items.map { item in
                ReceiptLabels.Item(
                    line: item.line,
                    nameLine: Self.line(item.nameLine),
                    quantityLine: Self.line(item.quantityLine),
                    discountLines: item.discountLines,
                    taxRate: EntryItem.TaxRate(rawValue: item.taxRate)
                )
            },
            discountLines: discountLines
        )
    }

    static func line(_ number: Int) -> Int? {
        number >= 0 ? number : nil
    }
}
