import Core
import DesignSystem
import FeatureModels
import SwiftUI

public extension View {
    func undoNotice<Item>(
        _ notice: UndoNotice<Item>,
        message: String = "非表示にしました",
        systemImage: String = "eye.slash",
        bottom: CGFloat = NoticeBanner.bottomMargin,
        onUndo: @escaping (Item) -> Void
    ) -> some View {
        overlay(alignment: .bottom) {
            if let item = notice.current {
                NoticeBanner(
                    message,
                    systemImage: systemImage,
                    actionTitle: "取り消す"
                ) {
                    notice.dismiss()
                    onUndo(item)
                }
                .padding(.horizontal, NoticeBanner.sideMargin)
                .padding(.bottom, bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: notice.id)
        .haptic(.success, trigger: notice.id) { _, new in
            new != nil
        }
    }

    func deletionNotice(
        _ notice: UndoNotice<Deletion>,
        note: String? = nil,
        bottom: CGFloat = NoticeBanner.bottomMargin,
        onUndo: @escaping (Deletion) -> Void
    ) -> some View {
        let subject = notice.current?.subject?.noticeMessage ?? "削除しました"
        let message = note.map { "\(subject)（\($0)）" } ?? subject

        return undoNotice(
            notice,
            message: message,
            systemImage: "trash",
            bottom: bottom,
            onUndo: onUndo
        )
    }
}
