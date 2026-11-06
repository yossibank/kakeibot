import Core
import DesignSystem
import SwiftUI

extension EntrySheet {
    var header: some View {
        HStack {
            RingButton(systemImage: "xmark") {
                close()
            }
            .frame(width: Self.slotSize, alignment: .leading)

            Spacer()

            CapsulePicker(selection: typeBinding, options: Self.typeOptions)

            Spacer()

            deleteButton
                .frame(
                    width: Self.slotSize,
                    height: Self.slotSize,
                    alignment: .trailing
                )
        }
    }
}

private extension EntrySheet {
    static let slotSize: CGFloat = 44

    static let typeOptions: [CapsulePicker<Entry.Kind>.Option] = [
        .init("支出", value: .expense),
        .init("収入", value: .income),
        .init("振替", value: .transfer)
    ]

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
                    showSelectedCategory()
                }
            }
        )
    }
}

private extension EntrySheet {
    @ViewBuilder
    var deleteButton: some View {
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
    }
}
