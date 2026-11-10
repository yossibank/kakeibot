extension WhatsNewRelease {
    static let v1_2_0 = WhatsNewRelease(
        version: "1.2.0",
        month: "2026年11月",
        features: [
            Feature(
                systemImage: "creditcard",
                title: "カードの未払いの記録",
                shortTitle: "未払い",
                lead: "まだ引き落とされていない記録を、まとめて見られます",
                points: [
                    "次の引き落としの日と合計を表示します",
                    "引き落としの回ごとに記録を並べます"
                ],
                steps: [
                    Step(scene: .unpaidRow, caption: "カードの行"),
                    Step(scene: .unpaidButton, caption: "「未払いの記録を見る」を押す"),
                    Step(scene: .unpaidList, caption: "合計と記録が並ぶ")
                ],
                action: .assets,
                actionTitle: "資産を開く"
            ),
            Feature(
                systemImage: "arrow.turn.down.right",
                title: "固定費とテンプレートの請求",
                shortTitle: "請求",
                lead: "カードの記録を、次の引き落としに回せます",
                points: [
                    "「次に回す」「2 回先」を選べます",
                    "記録を作るたびに、選んだ回に入ります"
                ],
                steps: [
                    Step(scene: .shiftWallet, caption: "カードを選ぶ"),
                    Step(scene: .shiftChoice, caption: "「次に回す」を押す"),
                    Step(scene: .shiftBill, caption: "次の引き落としに入る")
                ],
                action: .setup(.recurrings),
                actionTitle: "固定費を開く"
            ),
            Feature(
                systemImage: "repeat",
                title: "固定費を種類ごとに",
                shortTitle: "固定費",
                lead: "支出・収入・振替を分けて並べます",
                points: [
                    "上のタブで種類を切り替えられます",
                    "作る画面が 1 画面に収まりました"
                ],
                steps: [
                    Step(scene: .recurringRow, caption: "「固定費」を開く"),
                    Step(scene: .recurringTabs, caption: "「収入」を押す"),
                    Step(scene: .recurringList, caption: "収入だけが並ぶ")
                ],
                action: .setup(.recurrings),
                actionTitle: "固定費を開く"
            )
        ]
    )
}
