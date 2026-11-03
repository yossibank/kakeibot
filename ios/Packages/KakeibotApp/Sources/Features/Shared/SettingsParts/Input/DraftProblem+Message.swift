import Core

extension DraftProblem {
    var message: String {
        switch self {
        case .emptyName: "名前を入れてください"
        case .emptyAmount: "金額を入れてください"
        case .emptyMark: "アイコンを選んでください"
        case .textTooLong: "アイコンの文字は \(IconDraft.maxTextLength) 文字までです"
        case .invalidColor: "色を選んでください"
        case .nameTooLong: "名前は \(ThemeDraft.maxNameLength) 文字までです"
        case .unreadableColors: "文字が読みにくい色です"
        case .kindLocked: "記録がある口座は、資産と負債をまたいで種類を変えられません"
        case .valuedKindLocked: "評価額がある口座は、投資から種類を変えられません"
        }
    }
}
