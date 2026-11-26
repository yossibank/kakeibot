import Core
import DesignSystem
import FeatureModels
import SwiftUI

public struct ThemeEditSheet: View {
    @State private var model: ThemeEditModel

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

            form

            if focus == nil {
                PrimaryButton(model.saveTitle) {
                    save()
                }
                .disabled(!model.canSave)
                .transition(.opacity)
            }
        }
        .animation(.snappy, value: focus == nil)
        .padding(.horizontal, SettingsSpacing.side)
        .padding(.top, SettingsSpacing.top)
        .padding(.bottom, 8)
        .contentShape(.rect)
        .onTapGesture {
            focus = nil
        }
        .backdrop()
        .errorBanner(Bindable(model.state).errorNotice)
        .confirmsDiscard(
            when: model.isChanged,
            isPresented: Bindable(model.state).prompt.isConfirmingDiscard
        ) {
            dismiss()
        }
        .confirmation(
            isPresented: Bindable(model.state).prompt.isConfirmingDelete,
            systemImage: "trash",
            title: "このテーマを削除しますか",
            message: "選んでいるときは、ホワイトに戻ります",
            keepTitle: "やめる",
            confirmTitle: "削除する"
        ) {
            model.perform {
                await $0.delete()
            }
        }
        .onOutcome(model.state.outcome) { outcome in
            if let deletion = outcome.deletion {
                onDelete(deletion)
            }

            dismiss()
        }
    }
}

private extension ThemeEditSheet {
    enum Field: Hashable {
        case name
    }
}

private extension ThemeEditSheet {
    var header: some View {
        SettingsEditHeader(
            isMenuOpen: Bindable(model.state).prompt.isMenuOpen,
            title: model.isEditing ? "テーマを編集" : "テーマを追加",
            isEditing: model.isEditing,
            isHidden: false,
            canHide: false
        ) {
            close()
        } onHide: {} onDelete: {
            focus = nil
            model.state.prompt.isConfirmingDelete = true
        }
    }

    var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SettingsSpacing.form) {
                ThemePreview(palette: model.output.palette)
                    .frame(width: 150)
                    .frame(maxWidth: .infinity)

                SettingsField(
                    "名前",
                    text: Bindable(model.state).draft.name,
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
    }

    func colorRow(_ slot: ThemeEditModel.Slot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsSectionTitle(slot.title)

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
        let isSelected = model.state.draft[keyPath: slot.keyPath] == hex
        let isAvailable = model.output.isAvailable(hex, for: slot)
        let ring = isSelected ? Palette.accent : Palette.line
        let ringWidth: CGFloat = isSelected ? 2 : 1
        let opacity: Double = isAvailable ? 1 : 0.35
        let color = Color(hex: hex) ?? .clear

        return Button {
            model.state.choose(hex, for: slot)
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
    static let fade: CGFloat = 16

    static let swatchColumns = [
        GridItem(.adaptive(minimum: 36), spacing: 8)
    ]

    func colorBinding(_ slot: ThemeEditModel.Slot) -> Binding<Color> {
        Binding {
            Color(hex: model.state.draft[keyPath: slot.keyPath]) ?? .clear
        } set: { color in
            model.state.choose(color.hex, for: slot)
        }
    }

    func close() {
        focus = nil

        if model.isChanged {
            model.state.prompt.isConfirmingDiscard = true
        } else {
            dismiss()
        }
    }

    func save() {
        focus = nil

        model.perform {
            await $0.save()
        }
    }
}
