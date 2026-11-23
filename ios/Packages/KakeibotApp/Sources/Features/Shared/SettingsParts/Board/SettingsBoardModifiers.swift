import DesignSystem
import SwiftUI

extension View {
    func settingsBoardHaptics<ID: Hashable>(
        _ drag: SettingsDrag<ID>,
        movingOrder: [ID]?
    ) -> some View {
        haptic(.impact(weight: .medium), trigger: drag.liftCount)
            .haptic(.selection, trigger: movingOrder)
            .haptic(.success, trigger: drag.showCount)
    }

    @ViewBuilder
    func settingsSharesTextScale(_ id: (some Equatable)?) -> some View {
        if let id {
            sharesTextScale(id: id)
        } else {
            self
        }
    }

    func settingsDeleteHiddenConfirmation(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        onConfirm: @escaping () -> Void
    ) -> some View {
        confirmation(
            isPresented: isPresented,
            systemImage: "trash",
            title: title,
            message: message,
            keepTitle: "やめる",
            confirmTitle: "まとめて削除する",
            onConfirm: onConfirm
        )
    }
}
