extension WhatsNewRelease {
    static let v1_6_0 = WhatsNewRelease(
        version: "1.6.0",
        month: "2026年11月",
        features: [
            Feature(
                systemImage: "mic",
                title: "声で記録",
                shortTitle: "声",
                lead: "話すだけで記録を入れられます",
                points: [
                    "金額・カテゴリ・口座・日付・メモを読み取ります",
                    "話し終えて 1 秒たつと、読み取った内容が入ります",
                    "声は端末の中で聞き取り、保存しません"
                ],
                steps: [
                    Step(scene: .voiceButton, caption: "金額の右のマイクを押す"),
                    Step(scene: .voiceListen, caption: "使ったものと金額を話す"),
                    Step(scene: .voiceFilled, caption: "読み取った内容が入る")
                ],
                action: .entry,
                actionTitle: "記録する"
            ),
            Feature(
                systemImage: "square.and.pencil",
                title: "新しい入力シート",
                shortTitle: "入力",
                lead: "記録の入力を、1 枚のカードにまとめました",
                points: [
                    "カテゴリ・口座・日付・金額を 1 枚で見渡せます",
                    "前に使った口座から始まります",
                    "テンプレートと最近の記録から、すぐに入れられます"
                ],
                steps: [
                    Step(scene: .entrySlip, caption: "1 枚のカードで見渡す"),
                    Step(scene: .entryDeck, caption: "テンキーで金額を入れる"),
                    Step(scene: .entryShortcuts, caption: "テンプレートから入れる")
                ],
                action: .entry,
                actionTitle: "記録する"
            )
        ]
    )
}
