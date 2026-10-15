import Core
import DesignSystem
import SwiftUI

public struct RecordedNotice: Equatable {
    public let entryId: Entry.ID
    public let message: String
}

extension View {
    func recordedBanner(
        _ notice: RecordedNotice?,
        onUndo: @escaping () -> Void,
        onClear: @escaping () -> Void
    ) -> some View {
        modifier(
            RecordedBanner(
                notice: notice,
                onUndo: onUndo,
                onClear: onClear
            )
        )
    }
}

private struct RecordedBanner: ViewModifier {
    let notice: RecordedNotice?
    let onUndo: () -> Void
    let onClear: () -> Void

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let notice {
                    NoticeBanner(
                        notice.message,
                        systemImage: "checkmark",
                        actionTitle: "取り消す",
                        action: onUndo
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.snappy, value: notice)
            .sensoryFeedback(.success, trigger: notice) { _, new in
                new != nil
            }
            .task(id: notice) {
                guard notice != nil else {
                    return
                }

                guard await (try? Task.sleep(for: .seconds(4))) != nil else {
                    return
                }

                onClear()
            }
    }
}
