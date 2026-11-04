public struct WhatsNewRelease: Identifiable, Sendable {
    let version: String
    let month: String
    let features: [Feature]

    public var id: String {
        version
    }
}

public extension WhatsNewRelease {
    enum Action: Hashable, Sendable {
        case entry
        case assets
        case setup(SetupItem)
    }

    static var latestVersion: String {
        all.first?.version ?? "0"
    }
}

extension WhatsNewRelease {
    struct Feature: Identifiable, Sendable {
        let systemImage: String
        let title: String
        let shortTitle: String
        let lead: String
        let points: [String]
        var note: String?
        let steps: [Step]
        let action: Action?
        let actionTitle: String

        var id: String {
            title
        }
    }

    struct Step: Hashable, Sendable {
        let scene: WhatsNewScene.Kind
        let caption: String
    }

    static let all = [
        WhatsNewRelease(
            version: "1.2.0",
            month: "2026年11月",
            features: [
                Feature(
                    systemImage: "creditcard",
                    title: "カードの未払いの記録",
                    shortTitle: "未払い",
                    lead: "まだ引き落とされていない記録を、まとめて見られます",
                    points: [
                        "次の引き落としの日と合計を出す",
                        "引き落としの回ごとに記録を並べる"
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
                        "「次に回す」「2 回先」を選べる",
                        "記録を作るたびに、選んだ回に入る"
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
                        "上のタブで種類を切り替える",
                        "作る画面は 1 画面に収まる"
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
        ),
        WhatsNewRelease(
            version: "1.1.0",
            month: "2026年11月",
            features: [
                Feature(
                    systemImage: "doc.text.viewfinder",
                    title: "レシートを撮って記録",
                    shortTitle: "レシート",
                    lead: "撮るだけで、品目まで入ります",
                    points: [
                        "品目・合計・日付・店名を読む",
                        "合計が合わない品目には色が付く",
                        "直した品名を、店ごとに覚える"
                    ],
                    note: "iOS 26 以降で Apple Intelligence をオンにすると、品目をより正しく読めます",
                    steps: [
                        Step(scene: .receiptButton, caption: "「レシート」を押す"),
                        Step(scene: .receiptCamera, caption: "レシートを撮る"),
                        Step(scene: .receiptItems, caption: "品目が入る")
                    ],
                    action: .entry,
                    actionTitle: "入力シートを開く"
                ),
                Feature(
                    systemImage: "list.bullet.rectangle",
                    title: "記録の品目",
                    shortTitle: "品目",
                    lead: "1 つの記録に、買った物を並べられます",
                    points: [
                        "品目ごとに金額と個数を入れる",
                        "8% と 10% の消費税を分けて出す",
                        "記録の一覧で品名を探せる"
                    ],
                    steps: [
                        Step(scene: .itemsAdd, caption: "「＋ 品目」を押す"),
                        Step(scene: .itemsSlip, caption: "品名と金額を入れる"),
                        Step(scene: .itemsList, caption: "税率ごとに並ぶ")
                    ],
                    action: .entry,
                    actionTitle: "入力シートを開く"
                ),
                Feature(
                    systemImage: "arrow.uturn.forward.circle",
                    title: "予算の繰越",
                    shortTitle: "繰越",
                    lead: "余った予算を、次の期間に回せます",
                    points: [
                        "残りは次の予算に足す",
                        "使いすぎた分は次の予算から引く"
                    ],
                    steps: [
                        Step(scene: .carryoverSwitch, caption: "繰り越すにする"),
                        Step(scene: .carryoverLeft, caption: "残りが出る"),
                        Step(scene: .carryoverNext, caption: "次の予算に足す")
                    ],
                    action: .setup(.budget),
                    actionTitle: "予算を開く"
                ),
                Feature(
                    systemImage: "calendar.badge.clock",
                    title: "月の始まりを平日に",
                    shortTitle: "月の始まり",
                    lead: "給料日が休みの月も、合わせて数えられます",
                    points: [
                        "土日・祝日なら、前か次の平日にずらす",
                        "期間と予算も、ずらした日から数える"
                    ],
                    steps: [
                        Step(scene: .monthStartDay, caption: "始まりの日を選ぶ"),
                        Step(scene: .monthStartShift, caption: "「前の平日」を押す"),
                        Step(scene: .monthStartPeriod, caption: "期間がずれる")
                    ],
                    action: .setup(.monthStart),
                    actionTitle: "月の始まりを開く"
                )
            ]
        )
    ]
}
