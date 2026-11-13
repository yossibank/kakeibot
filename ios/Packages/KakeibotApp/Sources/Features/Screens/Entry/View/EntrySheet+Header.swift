import Core
import DesignSystem
import SwiftUI

extension EntrySheet {
    var header: some View {
        HStack(spacing: 8) {
            EntryTypeSwitch(selection: typeBinding)

            Spacer(minLength: 0)

            if model.isEditing {
                RingButton(
                    systemImage: "trash",
                    style: .destructive,
                    label: "削除"
                ) {
                    Task {
                        await delete()
                    }
                }
            }

            RingButton(systemImage: "xmark") {
                close()
            }
        }
    }
}

private extension EntrySheet {
    var typeBinding: Binding<Entry.Kind> {
        Binding(
            get: {
                model.type
            },
            set: { type in
                var transaction = Transaction()

                transaction.disablesAnimations = true

                withTransaction(transaction) {
                    model.select(type)
                    resetDeck()
                    showSelectedCategory()
                }
            }
        )
    }
}
