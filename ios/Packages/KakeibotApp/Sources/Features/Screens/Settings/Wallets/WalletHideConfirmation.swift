import DesignSystem
import SwiftUI

extension View {
    func confirmsWalletHide(
        balance: Int,
        isPresented: Binding<Bool>,
        onConfirm: @escaping () -> Void
    ) -> some View {
        let amount = AmountText.text(balance)

        return confirmation(
            isPresented: isPresented,
            systemImage: "eye.slash",
            title: "この口座を非表示にしますか",
            message: "残高 \(amount) は、資産タブの合計から外れます",
            keepTitle: "やめる",
            confirmTitle: "非表示にする",
            onConfirm: onConfirm
        )
    }

    func confirmsWalletDelete(
        hasEntries: Bool,
        isPresented: Binding<Bool>,
        onHide: @escaping () -> Void,
        onConfirm: @escaping () -> Void
    ) -> some View {
        let text = WalletDeleteText(hasEntries: hasEntries)

        return confirmation(
            isPresented: isPresented,
            systemImage: text.systemImage,
            title: text.title,
            message: text.message,
            keepTitle: "やめる",
            confirmTitle: text.confirmTitle,
            role: text.role
        ) {
            if hasEntries {
                onHide()
            } else {
                onConfirm()
            }
        }
    }
}

private struct WalletDeleteText {
    let hasEntries: Bool
}

private extension WalletDeleteText {
    static let hasEntriesMessage = "記録があります。非表示にすると、記録を残したまま一覧から外せます"

    var systemImage: String {
        hasEntries ? "eye.slash" : "trash"
    }

    var title: String {
        hasEntries ? "この口座は削除できません" : "この口座を削除しますか"
    }

    var message: String {
        hasEntries ? Self.hasEntriesMessage : "使っている固定費・テンプレート・評価額も消えます"
    }

    var confirmTitle: String {
        hasEntries ? "非表示にする" : "削除する"
    }

    var role: ConfirmCard.Role {
        hasEntries ? .suggestion : .destructive
    }
}
