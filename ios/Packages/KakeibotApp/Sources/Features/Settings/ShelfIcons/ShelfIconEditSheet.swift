import Core
import DesignSystem
import Store
import SwiftUI

public struct ShelfIconEditSheet: View {
    @State private var model: ShelfIconEditModel
    @State private var isConfirmingDiscard = false
    @State private var isConfirmingRemove = false

    @FocusState private var focus: Field?

    @Environment(\.dismiss) private var dismiss

    public init(model: ShelfIconEditModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        VStack(spacing: 16) {
            header

            ScrollView {
                VStack(spacing: 16) {
                    IconBadge(model.icon.preview, size: 86)

                    IconEditor(
                        model: model.icon,
                        focus: $focus,
                        textField: .text
                    )
                }
                .padding(.bottom, 8)
                .padding(.vertical, Self.fade)
            }
            .scrollIndicators(.hidden)
            .edgeFade(Self.fade)
            .padding(.vertical, -Self.fade)
            .scrollDismissesKeyboard(.interactively)

            PrimaryButton(model.saveTitle) {
                Task {
                    await save()
                }
            }
            .disabled(!model.canSave)
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 8)
        .contentShape(.rect)
        .onTapGesture {
            focus = nil
        }
        .background {
            Rectangle()
                .fill(Palette.night)
                .ignoresSafeArea()
        }
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .preferredColorScheme(.dark)
        .confirmsDiscard(
            when: model.isChanged,
            isPresented: $isConfirmingDiscard
        ) {
            dismiss()
        }
        .confirmsShelfIconDelete(isPresented: $isConfirmingRemove) {
            Task {
                await remove()
            }
        }
        .task {
            await model.load()
        }
    }
}

private extension ShelfIconEditSheet {
    var header: some View {
        HStack {
            RingButton(systemImage: "xmark") {
                close()
            }

            Spacer()

            Text(model.isEditing ? "アイコンを編集" : "アイコンを追加")
                .font(.serif(.body))
                .tracking(4)
                .foregroundStyle(Palette.gold)

            Spacer()

            if model.isEditing {
                RingButton(systemImage: "trash", label: "消す") {
                    focus = nil
                    isConfirmingRemove = true
                }
            } else {
                Color.clear
                    .frame(width: 44, height: 44)
            }
        }
    }
}

private extension ShelfIconEditSheet {
    enum Field: Hashable {
        case text
    }

    static let fade: CGFloat = 16

    func close() {
        focus = nil

        if model.isChanged {
            isConfirmingDiscard = true
        } else {
            dismiss()
        }
    }

    func save() async {
        focus = nil

        if await model.save() {
            dismiss()
        }
    }

    func remove() async {
        if await model.remove() {
            dismiss()
        }
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        ShelfIconEditSheet(model: ShelfIconEditModel(database: database))
    }
}
