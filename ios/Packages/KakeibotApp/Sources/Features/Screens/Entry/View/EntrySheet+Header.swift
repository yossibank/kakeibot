import Core
import DesignSystem
import SwiftUI

extension EntrySheet {
    var header: some View {
        HStack {
            RingButton(systemImage: "xmark") {
                close()
            }
            .frame(width: headerSideWidth, alignment: .leading)

            Spacer()

            CapsulePicker(selection: typeBinding, options: Self.typeOptions)

            Spacer()

            editActions
                .frame(
                    width: headerSideWidth,
                    height: Self.slotSize,
                    alignment: .trailing
                )
        }
    }
}

private extension EntrySheet {
    static let slotSize: CGFloat = 44
    static let editActionSpacing: CGFloat = 12

    static let typeOptions: [CapsulePicker<Entry.Kind>.Option] = [
        .init("支出", value: .expense),
        .init("収入", value: .income),
        .init("振替", value: .transfer)
    ]

    var headerSideWidth: CGFloat {
        model.isEditing ? Self.slotSize * 2 + Self.editActionSpacing : Self.slotSize
    }

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
    var editActions: some View {
        HStack(spacing: Self.editActionSpacing) {
            if model.isEditing {
                RingButton(systemImage: "doc.on.doc", label: "もう一度") {
                    Task {
                        await recordAgain()
                    }
                }

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
}

private extension EntrySheet {
    func recordAgain() async {
        await model.recordAgain()
        showSelectedCategory()
    }
}
