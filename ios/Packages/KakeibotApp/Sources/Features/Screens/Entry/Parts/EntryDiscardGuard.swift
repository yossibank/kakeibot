import DesignSystem
import FeatureModels
import SwiftUI

struct EntryDiscardGuard: ViewModifier {
    @Binding var isPresented: Bool

    let model: EntryModel
    let onDiscard: () -> Void

    func body(content: Content) -> some View {
        content.confirmsDiscard(
            when: model.output.isChanged,
            isPresented: $isPresented,
            onDiscard: onDiscard
        )
    }
}
