import DesignSystem
import SwiftUI

struct SettingsConfirmation {
    let systemImage: String
    let title: String
    let message: String
    let confirmTitle: String

    var role: ConfirmCard.Role = .destructive
    var confirmsHide = false
}

extension SettingsConfirmation {
    static let empty = SettingsConfirmation(
        systemImage: "",
        title: "",
        message: "",
        confirmTitle: ""
    )

    static func delete(
        title: String,
        message: String
    ) -> SettingsConfirmation {
        SettingsConfirmation(
            systemImage: "trash",
            title: title,
            message: message,
            confirmTitle: "削除する"
        )
    }
}

extension View {
    func settingsConfirmation(
        _ confirmation: SettingsConfirmation?,
        isPresented: Binding<Bool>,
        onConfirm: @escaping () -> Void
    ) -> some View {
        let text = confirmation ?? .empty

        return self.confirmation(
            isPresented: isPresented,
            systemImage: text.systemImage,
            title: text.title,
            message: text.message,
            keepTitle: "やめる",
            confirmTitle: text.confirmTitle,
            role: text.role,
            onConfirm: onConfirm
        )
    }
}
