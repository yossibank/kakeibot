struct ProFeature: Identifiable {
    let art: FeatureArt.Kind
    let systemImage: String
    let name: String
    let headline: String
    let points: [String]

    var id: String {
        name
    }
}

extension ProFeature {
    static let all = [
        ProFeature(
            art: .receipt,
            systemImage: "doc.text.viewfinder",
            name: "レシートの読み取り",
            headline: "撮るだけで、品目まで記録",
            points: [
                "品目・合計・日付・店名をまとめて読みます",
                "8% と 10% の消費税も分けて出します",
                "回数を気にせず使えます（無料は 3 回まで）"
            ]
        ),
        ProFeature(
            art: .sync,
            systemImage: "icloud",
            name: "端末間の同期",
            headline: "iPhone を替えても、続きから",
            points: [
                "記録も設定も、自分の iCloud でそろいます",
                "機種を替えても、移し替えはいりません",
                "記録は自分の iCloud にだけ置きます"
            ]
        ),
        ProFeature(
            art: .share,
            systemImage: "person.2",
            name: "家族との共有",
            headline: "家族の財布を、ふたりで",
            points: [
                "共有した財布の記録を、一緒につけられます",
                "自分の家計簿は、共有せずにそのまま",
                "招待された人は、Pro が無くても使えます"
            ]
        ),
        ProFeature(
            art: .theme,
            systemImage: "paintpalette",
            name: "テーマを作る",
            headline: "好きな色で、自分だけのテーマに",
            points: [
                "背景・カード・文字・差し色を選べます",
                "読みにくい組み合わせは、保存の前に知らせます",
                "ウィジェットにも同じ色が付きます"
            ]
        ),
        ProFeature(
            art: .fonts,
            systemImage: "textformat",
            name: "4 つの字体",
            headline: "金額の表情を、字体で変える",
            points: [
                "丸ゴシック・手書き・ドット・ポップから選べます",
                "金額と見出しの字体が変わります",
                "明朝とゴシックは、無料のまま使えます"
            ]
        )
    ]
}
