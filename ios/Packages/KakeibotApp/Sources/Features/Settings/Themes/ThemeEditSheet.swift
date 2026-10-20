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

    public init(model: ThemeEditModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        VStack(spacing: 16) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ThemePreview(palette: model.palette)
                        .frame(width: 150)
                        .frame(maxWidth: .infinity)

                    SettingsField(
                        "名前",
                        text: $model.draft.name,
                        font: .body,
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
            title: "このテーマを削除しますか",
            message: "選んでいるときは、ネイビーに戻ります",
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
        HStack {
            RingButton(systemImage: "xmark") {
                close()
            }

            Spacer()

            Text(model.isEditing ? "テーマを編集" : "テーマをつくる")
                .font(.serif(.body))
                .tracking(4)
                .foregroundStyle(Palette.accent)

            Spacer()

            if model.isEditing {
                RingButton(systemImage: "trash") {
                    focus = nil
                    isConfirmingDelete = true
                }
            } else {
                Color.clear
                    .frame(width: 44, height: 44)
            }
        }
    }

    func colorRow(_ slot: ThemeEditModel.Slot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(slot.title)
                .font(.caption2)
                .tracking(3)
                .foregroundStyle(Palette.accent)
                .padding(.leading, 6)

            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(slot.swatches, id: \.self) { hex in
                        swatch(hex, in: slot)
                    }

                    ColorPicker(
                        slot.title,
                        selection: colorBinding(slot),
                        supportsOpacity: false
                    )
                    .labelsHidden()
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
        }
    }

    func swatch(
        _ hex: String,
        in slot: ThemeEditModel.Slot
    ) -> some View {
        let isSelected = model.draft[keyPath: slot.keyPath] == hex
        let ring = isSelected ? Palette.accent : Palette.line

        return Button {
            model.draft[keyPath: slot.keyPath] = hex
        } label: {
            Circle()
                .fill(Color(hex: hex) ?? .clear)
                .frame(width: 30, height: 30)
                .padding(3)
                .overlay {
                    Circle()
                        .stroke(ring, lineWidth: isSelected ? 2 : 1)
                }
        }
        .buttonStyle(.plain)
    }
}

private extension ThemeEditSheet {
    enum Field: Hashable {
        case name
    }

    static let fade: CGFloat = 16

    func colorBinding(_ slot: ThemeEditModel.Slot) -> Binding<Color> {
        Binding {
            Color(hex: model.draft[keyPath: slot.keyPath]) ?? .clear
        } set: { color in
            model.draft[keyPath: slot.keyPath] = color.hex
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
        if await model.delete() {
            dismiss()
        }
    }
}
