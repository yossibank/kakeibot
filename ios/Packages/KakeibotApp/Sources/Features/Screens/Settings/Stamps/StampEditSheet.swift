import Core
import DesignSystem
import Store
import SwiftUI

public struct StampEditSheet: View {
    @State private var model: StampEditModel
    @State private var isConfirmingDiscard = false
    @State private var isConfirmingHideChanges = false
    @State private var isConfirmingDelete = false

    @FocusState private var focus: Field?

    @Environment(\.dismiss) private var dismiss

    private let onDelete: (Deletion) -> Void
    private let onHide: () -> Void

    public init(
        model: StampEditModel,
        onDelete: @escaping (Deletion) -> Void = { _ in },
        onHide: @escaping () -> Void = {}
    ) {
        _model = State(initialValue: model)

        self.onDelete = onDelete
        self.onHide = onHide
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
        .padding(.horizontal, 20)
        .padding(.top, 20)
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
        .confirmsUnsavedHide(
            isHidden: model.isHidden,
            canSave: model.canSave,
            isPresented: $isConfirmingHideChanges
        ) {
            Task {
                await save(hiding: true)
            }
        } onDiscard: {
            Task {
                await setHidden(!model.isHidden)
            }
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
            toggleHidden()
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

    func save(hiding: Bool = false) async {
        focus = nil

        if await model.save() {
            if hiding {
                guard await model.setHidden(!model.isHidden) else {
                    return
                }

                if model.isHidden {
                    onHide()
                }
            }

            dismiss()
        }
    }

    func toggleHidden() {
        guard model.isChanged else {
            Task {
                await setHidden(!model.isHidden)
            }

            return
        }

        isConfirmingHideChanges = true
    }

    func setHidden(_ isHidden: Bool) async {
        focus = nil

        if await model.setHidden(isHidden) {
            if isHidden {
                onHide()
            }

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
