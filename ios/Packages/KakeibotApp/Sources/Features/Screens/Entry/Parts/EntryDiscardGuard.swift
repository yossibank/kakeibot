import DesignSystem
import SwiftUI

struct EntryDiscardGuard: ViewModifier {
    @Binding var isPresented: Bool

    let model: EntryModel
    let onDiscard: () -> Void

    func body(content: Content) -> some View {
        content.confirmsDiscard(
            when: model.isChanged,
            isPresented: $isPresented,
            onDiscard: onDiscard
        )
    }
}
