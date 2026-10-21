import Core
import DesignSystem
import Store
import SwiftUI

public struct StampEditSheet: View {
    @State private var model: StampEditModel
    @State private var isConfirmingDiscard = false
    @State private var isConfirmingDelete = false

    @FocusState private var focus: Field?

    @Environment(\.dismiss) private var dismiss

    private let onDelete: (Deletion) -> Void

    public init(
        model: StampEditModel,
        onDelete: @escaping (Deletion) -> Void = { _ in }
    ) {
        _model = State(initialValue: model)
        self.onDelete = onDelete
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
                .fill(Palette.background)
                .ignoresSafeArea()
        }
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .confirmsDiscard(
            when: model.isChanged,
            isPresented: $isConfirmingDiscard
        ) {
            dismiss()
        }
        .confirmation(
            isPresented: $isConfirmingDelete,
            systemImage: "trash",
            title: "このスタンプを削除しますか",
            message: "カレンダーに押したスタンプは残ります",
            keepTitle: "やめる",
            confirmTitle: "削除する"
        ) {
            Task {
                await delete()
            }
        }
        .task {
            await model.load()
        }
    }
}

private extension StampEditSheet {
    var header: some View {
        SettingsEditHeader(
            title: model.isEditing ? "スタンプを編集" : "スタンプを追加",
            isEditing: model.isEditing,
            isHidden: model.isHidden
        ) {
            close()
        } onHide: {
            Task {
                await setHidden(!model.isHidden)
            }
        } onDelete: {
            isConfirmingDelete = true
        }
    }
}

private extension StampEditSheet {
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

    func setHidden(_ isHidden: Bool) async {
        focus = nil

        if await model.setHidden(isHidden) {
            dismiss()
        }
    }

    func delete() async {
        if let deletion = await model.delete() {
            onDelete(deletion)
            dismiss()
        }
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        StampEditSheet(model: StampEditModel(database: database))
    }
}
