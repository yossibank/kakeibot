import DesignSystem
import SwiftUI

extension View {
    func confirmsShelfIconDelete(
        isPresented: Binding<Bool>,
        onConfirm: @escaping () -> Void
    ) -> some View {
        confirmation(
            isPresented: isPresented,
            systemImage: "trash",
            title: "このアイコンを棚から消しますか",
            message: "押したスタンプとカテゴリ・口座のアイコンは残ります",
            keepTitle: "やめる",
            confirmTitle: "消す",
            onConfirm: onConfirm
        )
    }
}
