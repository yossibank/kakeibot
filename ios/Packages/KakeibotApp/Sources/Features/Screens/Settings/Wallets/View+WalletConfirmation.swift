import Core
import DesignSystem
import SwiftUI

extension View {
    func confirmsWalletHide(
        balance: Int,
        isPresented: Binding<Bool>,
        onConfirm: @escaping () -> Void
    ) -> some View {
        settingsConfirmation(
            .hidingWallet(balance: balance),
            isPresented: isPresented,
            onConfirm: onConfirm
        )
    }

    func confirmsWalletDelete(
        hasEntries: Bool,
        isPresented: Binding<Bool>,
        onHide: @escaping () -> Void,
        onConfirm: @escaping () -> Void
    ) -> some View {
        settingsConfirmation(
            .deletingWallet(hasEntries: hasEntries),
            isPresented: isPresented
        ) {
            if hasEntries {
                onHide()
            } else {
                onConfirm()
            }
        }
    }
}

extension SettingsConfirmation {
    static func hidingWallet(balance: Int) -> SettingsConfirmation {
        SettingsConfirmation(
            systemImage: "eye.slash",
            title: "この口座を非表示にしますか",
            message: "残高 \(Yen.text(balance)) は、資産タブの合計から外れます",
            confirmTitle: "非表示にする"
        )
    }

    static func deletingWallet(hasEntries: Bool) -> SettingsConfirmation {
        SettingsConfirmation(
            systemImage: hasEntries ? "eye.slash" : "trash",
            title: hasEntries ? "この口座は削除できません" : "この口座を削除しますか",
            message: hasEntries ? hasEntriesMessage : "使っている固定費・テンプレート・評価額も消えます",
            confirmTitle: hasEntries ? "非表示にする" : "削除する",
            role: hasEntries ? .suggestion : .destructive,
            confirmsHide: hasEntries
        )
    }
}

private extension SettingsConfirmation {
    static let hasEntriesMessage = "記録があります。非表示にすると、記録を残したまま一覧から外せます"
}
