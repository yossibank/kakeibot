import Store
import SwiftUI

public extension View {
    func deletionNotice(
        _ deletion: Binding<Deletion?>,
        bottom: CGFloat = 12,
        onUndo: @escaping (Deletion) -> Void
    ) -> some View {
        settingsHideNotice(
            deletion,
            message: "削除しました",
            systemImage: "trash",
            bottom: bottom,
            onUndo: onUndo
        )
    }
}
