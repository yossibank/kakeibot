import Core

extension DraftProblem {
    var message: String {
        switch self {
        case .emptyName: "名前を入れてください"
        case .emptyMark: "アイコンを選んでください"
        case .textTooLong: "アイコンの文字は \(IconDraft.maxTextLength) 文字までです"
        case .invalidColor: "色を選んでください"
        }
    }
}
