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

    func abilities(for widget: WidgetGuideWidget) -> [Ability] {
        switch self {
        case .home:
            widget.abilities

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
                    systemImage: "hand.tap",
                    title: "押すとホームへ",
                    detail: "押すと、アプリのホームを開きます"
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

    func steps(for widget: WidgetGuideWidget, size: WidgetGuideSize) -> [String] {
        switch self {
        case .home:
            [
                "ホーム画面の空いた所を長押しします",
                "左上の「編集」から「ウィジェットを追加」を選びます",
                "「かけいぼっと」を選び、左右になぞって「\(widget.title)」の「\(size.title)」を出します",
                "「ウィジェットを追加」を押します"
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
