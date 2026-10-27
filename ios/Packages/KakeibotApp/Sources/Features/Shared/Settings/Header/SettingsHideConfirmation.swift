import DesignSystem
import SwiftUI

extension View {
    func confirmsUnsavedHide(
        isHidden: Bool,
        canSave: Bool,
        isPresented: Binding<Bool>,
        onSave: @escaping () -> Void,
        onDiscard: @escaping () -> Void
    ) -> some View {
        let verb = isHidden ? "表示" : "非表示"

        return confirmation(
            isPresented: isPresented,
            systemImage: "pencil.slash",
            title: "保存していない変更があります",
            message: "入力した内容は、保存しないと残りません",
            keepTitle: "戻る",
            confirmTitle: "捨てて\(verb)",
            alternateTitle: canSave ? "保存して\(verb)" : nil,
            onAlternate: onSave,
            onConfirm: onDiscard
        )
    }
}
