import Core
import Store
import SwiftUI

@MainActor
protocol SettingsEditSheet: View {
    associatedtype EditModel

    init(
        model: EditModel,
        onDelete: @escaping (Deletion) -> Void,
        onHide: @escaping () -> Void
    )
}
