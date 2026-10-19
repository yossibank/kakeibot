import DesignSystem
import SwiftUI

extension View {
    func settingsHideNotice<ID: Hashable>(
        _ id: Binding<ID?>,
        message: String = "非表示にしました",
        onUndo: @escaping (ID) -> Void
    ) -> some View {
        overlay(alignment: .bottom) {
            if let hiddenId = id.wrappedValue {
                NoticeBanner(
                    message,
                    systemImage: "eye.slash",
                    actionTitle: "取り消す"
                ) {
                    id.wrappedValue = nil
                    onUndo(hiddenId)
                }
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .task(id: hiddenId) {
                    try? await Task.sleep(for: .seconds(4))

                    if id.wrappedValue == hiddenId {
                        id.wrappedValue = nil
                    }
                }
            }
        }
        .animation(.snappy, value: id.wrappedValue)
        .sensoryFeedback(.success, trigger: id.wrappedValue) { _, new in
            new != nil
        }
    }
}
