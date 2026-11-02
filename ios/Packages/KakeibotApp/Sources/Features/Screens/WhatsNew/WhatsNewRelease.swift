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
        case setup(SetupItem)
    }

    static var latestVersion: String {
        all.first?.version ?? "0"
    }
}

extension WhatsNewRelease {
    struct Feature: Identifiable, Sendable {
        let art: FeatureArt.Kind
        let title: String
        let text: String
        let action: Action?
        let actionTitle: String

        var id: String {
            title
        }
    }

    static let all = [
        WhatsNewRelease(
            version: "1.0",
            month: "2026年11月",
            features: [
                Feature(
                    art: .receipt,
                    title: "レシートを撮って記録",
                    text: "入力シートの「レシート」から撮ると、品目・合計・日付・店名まで読みます",
                    action: .entry,
                    actionTitle: "入力シートを開く"
                ),
                Feature(
                    art: .items,
                    title: "記録の品目",
                    text: "1 つの記録に品目を並べ、税率ごとの消費税も確かめられます。テンキーの上の「＋ 品目」から入れます",
                    action: .entry,
                    actionTitle: "入力シートを開く"
                ),
                Feature(
                    art: .carryover,
                    title: "予算の繰越",
                    text: "予算の画面で繰り越すにすると、残った予算を次の期間の予算に足します。使いすぎた分は引きます",
                    action: .setup(.budget),
                    actionTitle: "予算を開く"
                )
            ]
        )
    ]
}
