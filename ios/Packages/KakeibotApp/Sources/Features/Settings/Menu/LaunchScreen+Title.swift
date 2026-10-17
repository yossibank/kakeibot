import Core

extension LaunchScreen {
    var title: String {
        switch self {
        case .home: "ホーム"
        case .entry: "入力シート"
        }
    }

    var note: String {
        switch self {
        case .home: "今月あといくらと、最近の記録から始めます"
        case .entry: "開いてすぐ、記録を入れられます"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house"
        case .entry: "square.and.pencil"
        }
    }
}
