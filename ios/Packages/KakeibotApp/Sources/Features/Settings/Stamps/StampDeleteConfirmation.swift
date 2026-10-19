import DesignSystem
import SwiftUI

extension View {
    func confirmsStampDelete(
        isPresented: Binding<Bool>,
        onConfirm: @escaping () -> Void
    ) -> some View {
        confirmation(
            isPresented: isPresented,
            systemImage: "trash",
            title: "このスタンプを消しますか",
            message: "カレンダーに押したスタンプは残ります",
            keepTitle: "やめる",
            confirmTitle: "消す",
            onConfirm: onConfirm
        )
    }
}
