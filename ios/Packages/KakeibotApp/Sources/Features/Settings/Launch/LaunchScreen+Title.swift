import Core

extension LaunchScreen {
    var title: String {
        switch self {
        case .home: "ホーム"
        case .records: "記録"
        case .review: "振り返り"
        case .assets: "資産"
        case .entry: "入力シート"
        }
    }

    var note: String {
        switch self {
        case .home: "今月あといくらと、最近の記録から始めます"
        case .records: "日ごとの記録とカレンダーから始めます"
        case .review: "今月の使い方の振り返りから始めます"
        case .assets: "口座ごとの残高から始めます"
        case .entry: "開いてすぐ、記録を入れられます"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house"
        case .records: "calendar"
        case .review: "chart.pie"
        case .assets: "building.columns"
        case .entry: "square.and.pencil"
        }
    }
}
