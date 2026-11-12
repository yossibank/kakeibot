import Core
import Foundation
import FoundationModels
import OSLog

@available(iOS 26.0, *)
@MainActor
enum EntryVoiceModel {
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

    static func choose(
        in text: String,
        categories: [String],
        wallets: [String],
        examples: [String]
    ) async -> VoiceReading.Choice? {
        guard
            isUsable,
            !text.isEmpty
        else {
            return nil
        }

        let schema: GenerationSchema
        let response: LanguageModelSession.Response<GeneratedContent>

        do {
            schema = try Self.schema(categories: categories, wallets: wallets)
        } catch {
            logger.error("schema \(String(describing: error), privacy: .public)")
            return nil
        }

        let session = prepared ?? makeSession()
        prepared = nil

        do {
            response = try await session.respond(
                to: prompt(text, examples: examples),
                schema: schema,
                options: options
            )
        } catch {
            logger.error("respond \(String(describing: error), privacy: .public)")
            return nil
        }

        let category = try? response.content.value(String.self, forProperty: Self.categoryKey)
        let wallet = try? response.content.value(String.self, forProperty: Self.walletKey)

        return VoiceReading.Choice(
            categoryIndex: category.flatMap { categories.firstIndex(of: $0) },
            walletIndex: wallet.flatMap { wallets.firstIndex(of: $0) }
        )
    }

    static func schema(
        categories: [String],
        wallets: [String]
    ) throws -> GenerationSchema {
        let category = DynamicGenerationSchema(
            name: "Category",
            anyOf: choices(categories)
        )

        let wallet = DynamicGenerationSchema(
            name: "Wallet",
            anyOf: choices(wallets)
        )

        let answer = DynamicGenerationSchema(
            name: "Answer",
            properties: [
                .init(
                    name: categoryKey,
                    description: "話した文の支出や収入に当たるカテゴリ",
                    schema: category
                ),
                .init(
                    name: walletKey,
                    description: "話した文で払った口座・受け取った口座",
                    schema: wallet
                )
            ]
        )

        return try GenerationSchema(root: answer, dependencies: [])
    }
}

@available(iOS 26.0, *)
private extension EntryVoiceModel {
    static let logger = Logger(subsystem: "com.yossibank.kakeibot", category: "Voice")
    static let locale = Locale(identifier: "ja_JP")
    static let options = GenerationOptions(sampling: .greedy)
    static let categoryKey = "category"
    static let walletKey = "wallet"
    static let none = "当たるものが無い"

    static let instructions = """
    家計簿に記録するために話した日本語の文から、カテゴリと口座を選ぶ。
    カテゴリは、名前が文に無くても、買ったものや店や払う相手から考えて当てる。「駅前」のような場所の言葉や、「カードで」のような払い方の言葉では決めない。
    一覧に同じ意味の名前があれば、次の例のように選ぶ。
    - 食費：ランチ・コンビニ・スーパー・野菜・カフェ・コーヒー・パン屋・お弁当・居酒屋で一人で食べる
    - 日用品：ティッシュ・トイレットペーパー・洗剤・シャンプー・ドラッグストアの日用の品・100 円ショップ
    - 交通：電車・バス・タクシー・新幹線・飛行機・ガソリン・駐車場・交通費
    - 交際：飲み会・プレゼント・お祝い・お土産・香典・人へのおごり
    - 趣味：本・漫画・映画・ゲーム・ライブ・Netflix などの動画や音楽の定額。Amazon で本を買えば趣味
    - 衣服：服・靴・鞄・セーター・ユニクロ
    - 美容：美容院・ヘアカット・化粧品・ネイル
    - 医療：病院・歯医者・薬・診察
    - 住まい：家賃・管理費・更新料・火災保険などの住まいの保険・家具
    - 通信：携帯・スマホ・iPhone の代金や支払いや分割・Wi-Fi・ネット・回線・格安 SIM
    - 光熱：電気・ガス・水道
    口座は、文に口座の名前や払い方（カード・クレカ・現金・PayPay・Suica など）が出てきた時だけ選ぶ。現金は財布にする。払い方の話が無ければ「\(none)」にする。
    この人の前の記録の例があれば、同じ店や同じものはその例と同じカテゴリと口座にする。
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

    static func choices(_ names: [String]) -> [String] {
        var seen: Set<String> = []
        let distinct = names.filter { !$0.isEmpty && seen.insert($0).inserted }
        return distinct + [none]
    }

    static func prompt(
        _ text: String,
        examples: [String]
    ) -> String {
        var lines = ["話した文：\(text)"]

        if !examples.isEmpty {
            lines.append("この人の前の記録の例：")
            lines.append(contentsOf: examples)
        }

        return lines.joined(separator: "\n")
    }
}
