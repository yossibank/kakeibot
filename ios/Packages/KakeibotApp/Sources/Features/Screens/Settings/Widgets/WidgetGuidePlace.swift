enum WidgetGuidePlace: CaseIterable, Hashable {
    case home
    case lockScreen
    case control
}

extension WidgetGuidePlace {
    struct Ability: Hashable {
        let systemImage: String
        let title: String
        let detail: String
    }

    var title: String {
        switch self {
        case .home: "ホーム画面"
        case .lockScreen: "ロック画面"
        case .control: "コントロール"
        }
    }

    var abilities: [Ability] {
        switch self {
        case .home:
            [
                Ability(
                    systemImage: "gauge.with.needle",
                    title: "あといくら",
                    detail: "今月あといくら使えるかと、今日・今週・今月の支出、次の固定費を出します"
                ),
                Ability(
                    systemImage: "bolt",
                    title: "すぐ記録",
                    detail: "テンプレートを押すと、アプリを開かずにその場で記録します。5 秒のあいだ取り消せます"
                ),
                Ability(
                    systemImage: "pencil",
                    title: "金額を入れるもの",
                    detail: "鉛筆の印のテンプレートは、入力シートを開いて金額を入れます"
                )
            ]
        case .lockScreen:
            [
                Ability(
                    systemImage: "circle.dashed",
                    title: "丸と横長",
                    detail: "時計の下に、今月あといくら使えるかと今日の支出を出します"
                ),
                Ability(
                    systemImage: "text.line.first.and.arrowtriangle.forward",
                    title: "1 行",
                    detail: "時計の上に、残りを短く出します"
                ),
                Ability(
                    systemImage: "eye.slash",
                    title: "金額は伏せる",
                    detail: "ロックしている間は、金額を伏せて出します"
                )
            ]
        case .control:
            [
                Ability(
                    systemImage: "square.and.pencil",
                    title: "記録する",
                    detail: "押すと、今日の入力シートを開きます。ほかのアプリを使っている時もすぐ記録できます"
                ),
                Ability(
                    systemImage: "button.horizontal.top.press",
                    title: "ほかのボタンにも",
                    detail: "ロック画面の下のボタンや、アクションボタンにも割り当てられます"
                )
            ]
        }
    }

    var steps: [String] {
        switch self {
        case .home:
            [
                "ホーム画面の空いた所を長押しします",
                "左上の「編集」から「ウィジェットを追加」を選びます",
                "「かけいぼっと」を選び、置きたいものを選びます"
            ]
        case .lockScreen:
            [
                "ロック画面を長押しし、「カスタマイズ」を押します",
                "「ロック画面」を選び、時計の下の枠を押します",
                "「かけいぼっと」の「あといくら」を選びます"
            ]
        case .control:
            [
                "画面の右上から下へなぞり、コントロールセンターを開きます",
                "左上の ＋ を押し、「コントロールを追加」を選びます",
                "「かけいぼっと」の「記録する」を選びます"
            ]
        }
    }
}
