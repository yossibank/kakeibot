import Core
import DesignSystem
import Store
import SwiftUI

public struct TemplateEditSheet: View {
    @State private var model: TemplateEditModel
    @State private var isConfirmingDiscard = false

    @FocusState private var focus: Field?

    @Environment(\.dismiss) private var dismiss

    let onSave: (EntryTemplate) -> Void

    public init(
        model: TemplateEditModel,
        onSave: @escaping (EntryTemplate) -> Void = { _ in }
    ) {
        _model = State(initialValue: model)
        self.onSave = onSave
    }

    public var body: some View {
        content
            .ignoresSafeArea(.keyboard)
            .preferredColorScheme(.dark)
            .confirmsDiscard(
                when: model.isChanged,
                isPresented: $isConfirmingDiscard
            ) {
                dismiss()
            }
            .onChange(of: model.categoryId) {
                focus = nil
            }
            .onChange(of: model.walletId) {
                focus = nil
            }
            .task {
                await model.load()
            }
    }
}

private extension TemplateEditSheet {
    var content: some View {
        VStack(spacing: 14) {
            header
            field("名前（ランチ・定期など）", text: $model.name, focus: .name)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 12) {
                    CapsulePicker(selection: typeBinding, options: Self.types)
                    amountField
                }

                Text("金額を空にすると、使うときに入れる")
                    .font(.caption2)
                    .foregroundStyle(Palette.mist)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    section("カテゴリ") {
                        LazyVGrid(columns: Self.columns, spacing: 5) {
                            ForEach(model.categories) { category in
                                categoryButton(category)
                            }
                        }
                    }

                    section("財布") {
                        ScrollView(.horizontal) {
                            HStack(spacing: 8) {
                                ForEach(model.wallets) { wallet in
                                    walletButton(wallet)
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                    }

                    section("メモ") {
                        field("メモ（なくてもよい）", text: $model.memo, focus: .memo)
                    }
                }
                .padding(.bottom, 8)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(Palette.rose)
            }

            if model.isEditing {
                deleteButton
            }
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
    }

    var header: some View {
        HStack {
            RingButton(systemImage: "xmark") {
                close()
            }

            Spacer()

            Text(model.isEditing ? "テンプレートを編集" : "テンプレートを追加")
                .font(.system(size: 16, design: .serif))
                .tracking(4)
                .foregroundStyle(Palette.gold)

            Spacer()

            Button("保存") {
                Task {
                    await save()
                }
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(saveColor)
            .frame(minWidth: 44, minHeight: 44)
            .disabled(!model.canSave)
        }
    }

    var amountField: some View {
        HStack(spacing: 4) {
            Text("¥")
                .foregroundStyle(Palette.gold)

            TextField(
                "金額",
                text: amountBinding,
                prompt: Text("毎回入れる").foregroundStyle(Palette.dusk)
            )
            .keyboardType(.numberPad)
            .foregroundStyle(Palette.champagne)
            .tint(Palette.gold)
            .focused($focus, equals: .amount)
        }
        .font(.system(size: 20, weight: .medium, design: .serif))
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(Palette.drawer, in: .rect(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(fieldStroke(for: .amount), lineWidth: 1)
        }
        .animation(.snappy(duration: 0.2), value: focus)
    }

    var deleteButton: some View {
        Button {
            Task {
                await delete()
            }
        } label: {
            Text("このテンプレートを削除")
                .font(.subheadline)
                .foregroundStyle(Palette.rose)
                .frame(maxWidth: .infinity, minHeight: 46)
                .overlay {
                    Capsule()
                        .stroke(Palette.rose.opacity(0.45), lineWidth: 1)
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    func section(
        _ title: String,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption2)
                .tracking(3)
                .foregroundStyle(Palette.gold)

            content()
        }
    }

    func field(
        _ prompt: String,
        text: Binding<String>,
        focus field: Field
    ) -> some View {
        TextField(
            prompt,
            text: text,
            prompt: Text(prompt).foregroundStyle(Palette.dusk)
        )
        .font(.body)
        .foregroundStyle(Palette.ink)
        .tint(Palette.gold)
        .submitLabel(.done)
        .focused($focus, equals: field)
        .onSubmit {
            focus = nil
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(Palette.drawer, in: .rect(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(fieldStroke(for: field), lineWidth: 1)
        }
        .animation(.snappy(duration: 0.2), value: focus)
    }

    func categoryButton(_ category: EntryCategory) -> some View {
        let isSelected = model.categoryId == category.id
        let color = isSelected ? Palette.champagne : Palette.mist

        return Button {
            model.categoryId = category.id
        } label: {
            VStack(spacing: 4) {
                IconImage(model.icon(for: category), size: 17)

                Text(category.name)
                    .font(.system(size: 10))
                    .lineLimit(1)
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(
                tileFill(isSelected: isSelected),
                in: .rect(cornerRadius: 12)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(tileStroke(isSelected: isSelected), lineWidth: 1)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    func walletButton(_ wallet: Wallet) -> some View {
        let isSelected = model.walletId == wallet.id

        let color = isSelected ? Palette.champagne : Palette.mist

        return Button {
            model.walletId = wallet.id
        } label: {
            HStack(spacing: 6) {
                IconImage(model.icon(for: wallet), size: 13)

                Text(wallet.name)
                    .font(.caption)
            }
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(tileFill(isSelected: isSelected), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(tileStroke(isSelected: isSelected), lineWidth: 1)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private extension TemplateEditSheet {
    enum Field: Hashable {
        case name
        case amount
        case memo
    }

    static let types: [CapsulePicker<Entry.Kind>.Option] = [
        .init("支出", value: .expense),
        .init("収入", value: .income)
    ]

    static let columns = Array(
        repeating: GridItem(.flexible(), spacing: 5),
        count: 5
    )

    var saveColor: Color {
        model.canSave ? Palette.gold : Palette.dusk
    }

    var typeBinding: Binding<Entry.Kind> {
        Binding(
            get: {
                model.type
            },
            set: { type in
                model.select(type)
            }
        )
    }

    var amountBinding: Binding<String> {
        Binding(
            get: {
                model.amountText
            },
            set: { text in
                model.inputAmount(text)
            }
        )
    }

    func fieldStroke(for field: Field) -> Color {
        focus == field ? Palette.gold : Palette.gold.opacity(0.35)
    }

    func tileFill(isSelected: Bool) -> Color {
        isSelected ? Palette.gold.opacity(0.12) : Color.clear
    }

    func tileStroke(isSelected: Bool) -> Color {
        isSelected ? Palette.gold.opacity(0.55) : Palette.gold.opacity(0.12)
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

        guard let template = await model.save() else {
            return
        }

        onSave(template)
        dismiss()
    }

    func delete() async {
        if await model.delete() {
            dismiss()
        }
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        let _ = try? database.insertDefaultsIfEmpty(at: Date())
        TemplateEditSheet(model: TemplateEditModel(database: database))
    }
}
