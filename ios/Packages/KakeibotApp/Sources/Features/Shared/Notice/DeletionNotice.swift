import Store
import SwiftUI

public extension View {
    func deletionNotice(
        _ deletion: Binding<Deletion?>,
        note: String? = nil,
        bottom: CGFloat = 12,
        onUndo: @escaping (Deletion) -> Void
    ) -> some View {
        let subject = deletion.wrappedValue?.subject?.noticeMessage ?? "削除しました"
        let message = note.map { "\(subject)（\($0)）" } ?? subject

        return settingsHideNotice(
            deletion,
            message: message,
            systemImage: "trash",
            bottom: bottom,
            onUndo: onUndo
        )
    }
}

public extension Deletion.Subject {
    var noticeMessage: String {
        if count == 1,
           let name = names.first {
            return "\(name) を削除しました"
        }

        guard count > 1 else {
            return "\(kind.noun)を削除しました"
        }

        return "\(kind.noun) \(count) 件を削除しました"
    }
}

private extension Deletion.Kind {
    var noun: String {
        switch self {
        case .wallet: "口座"
        case .category: "カテゴリ"
        case .recurring: "固定費"
        case .template: "テンプレート"
        case .rewardRule: "決まり"
        case .theme: "テーマ"
        case .shelfIcon: "スタンプ"
        case .valuation: "評価額"
        case .adjustment: "残高の調整"
        }
    }
}
