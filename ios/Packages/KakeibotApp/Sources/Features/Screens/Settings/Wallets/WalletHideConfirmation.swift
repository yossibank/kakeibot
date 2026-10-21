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
        isPresented: Binding<Bool>,
        onConfirm: @escaping () -> Void
    ) -> some View {
        confirmation(
            isPresented: isPresented,
            systemImage: "trash",
            title: "この口座を削除しますか",
            message: "使っている固定費・テンプレート・評価額も消えます。元に戻せません",
            keepTitle: "やめる",
            confirmTitle: "削除する",
            onConfirm: onConfirm
        )
    }
}
