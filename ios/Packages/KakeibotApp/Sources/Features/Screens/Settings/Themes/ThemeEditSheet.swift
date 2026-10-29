import Core
import DesignSystem
import Store
import SwiftUI

public struct ThemeEditSheet: View {
    @State private var model: ThemeEditModel
    @State private var isConfirmingDiscard = false
    @State private var isConfirmingDelete = false

    @FocusState private var focus: Field?

    @Environment(\.dismiss) private var dismiss

    private let onDelete: (Deletion) -> Void

    public init(
        model: ThemeEditModel,
        onDelete: @escaping (Deletion) -> Void = { _ in }
    ) {
        _model = State(initialValue: model)

        self.onDelete = onDelete
    }

    public var body: some View {
        VStack(spacing: 16) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ThemePreview(palette: model.palette)
                        .frame(width: 150)
                        .frame(maxWidth: .infinity)

                    SettingsField(
                        "名前",
                        text: $model.draft.name,
                        focus: $focus,
                        field: .name
                    )

                    ForEach(ThemeEditModel.Slot.allCases, id: \.self) { slot in
                        colorRow(slot)
                    }
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
            Backdrop()
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
            title: "このテーマを削除しますか",
            message: "選んでいるときは、ホワイトに戻ります",
            keepTitle: "やめる",
            confirmTitle: "削除する"
        ) {
            Task {
                await delete()
            }
        }
    }
}

private extension ThemeEditSheet {
    var header: some View {
        SettingsEditHeader(
            title: model.isEditing ? "テーマを編集" : "テーマをつくる",
            isEditing: model.isEditing,
            isHidden: false,
            canHide: false
        ) {
            close()
        } onHide: {} onDelete: {
            focus = nil
            isConfirmingDelete = true
        }
    }

    func colorRow(_ slot: ThemeEditModel.Slot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(slot.title)
                .padding(.leading, 8)

            LazyVGrid(columns: Self.swatchColumns, spacing: 8) {
                ForEach(slot.swatches, id: \.self) { hex in
                    swatch(hex, in: slot)
                }

                ColorPicker(
                    slot.title,
                    selection: colorBinding(slot),
                    supportsOpacity: false
                )
                .labelsHidden()
                .frame(width: 36, height: 36)
            }
        }
    }

    func swatch(
        _ hex: String,
        in slot: ThemeEditModel.Slot
    ) -> some View {
        let isSelected = model.draft[keyPath: slot.keyPath] == hex
        let isAvailable = model.isAvailable(hex, for: slot)
        let ring = isSelected ? Palette.accent : Palette.line
        let ringWidth: CGFloat = isSelected ? 2 : 1
        let opacity: Double = isAvailable ? 1 : 0.35
        let color = Color(hex: hex) ?? .clear

        return Button {
            model.choose(hex, for: slot)
        } label: {
            Circle()
                .fill(color)
                .frame(width: 30, height: 30)
                .padding(4)
                .overlay {
                    Circle()
                        .stroke(ring, lineWidth: ringWidth)
                }
                .overlay {
                    if !isAvailable {
                        Image(systemName: "line.diagonal")
                            .sansFont(.body, weight: .light)
                            .foregroundStyle(Palette.hint)
                    }
                }
                .opacity(opacity)
        }
        .buttonStyle(.plain)
        .disabled(!isAvailable)
    }
}

private extension ThemeEditSheet {
    enum Field: Hashable {
        case name
    }

    static let fade: CGFloat = 16

    static let swatchColumns = [
        GridItem(.adaptive(minimum: 36), spacing: 8)
    ]

    func colorBinding(_ slot: ThemeEditModel.Slot) -> Binding<Color> {
        Binding {
            Color(hex: model.draft[keyPath: slot.keyPath]) ?? .clear
        } set: { color in
            model.choose(color.hex, for: slot)
        }
    }

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

    func delete() async {
        if let deletion = await model.delete() {
            onDelete(deletion)
            dismiss()
        }
    }
}
