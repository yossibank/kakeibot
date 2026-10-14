import Core
import DesignSystem
import Store
import SwiftUI

public struct TemplateEditSheet: View {
    @State private var model: TemplateEditModel
    @State private var isConfirmingDiscard = false
    @State private var isEnteringAmount = false

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
            .preferredColorScheme(.dark)
            .confirmsDiscard(
                when: model.isChanged,
                isPresented: $isConfirmingDiscard
            ) {
                dismiss()
            }
            .onChange(of: focus) {
                if focus != nil {
                    setEnteringAmount(false)
                }
            }
            .onChange(of: model.categoryId) {
                finishTyping()
            }
            .onChange(of: model.walletId) {
                finishTyping()
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

            ScrollViewReader { proxy in
                ScrollView {
                    form
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: focus) {
                    reveal(focus, in: proxy)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .overlay(alignment: .bottom) {
            if isEnteringAmount {
                keypadDrawer
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
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

            Text(title)
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

    var form: some View {
        VStack(alignment: .leading, spacing: 14) {
            field("名前（ランチ・定期など）", text: $model.name, focus: .name)

            VStack(alignment: .leading, spacing: 6) {
                amountField

                Text("金額を空にすると、使うときに入れる")
                    .font(.caption2)
                    .foregroundStyle(Palette.mist)
                    .padding(.leading, 4)
            }

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
            .id(Field.memo)

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(Palette.rose)
            }

            if model.isEditing {
                deleteButton
            }
        }
        .padding(.top, 4)
        .padding(.bottom, bottomSpace)
        .contentShape(.rect)
        .onTapGesture {
            finishTyping()
        }
    }

    var amountField: some View {
        Button {
            focus = nil
            setEnteringAmount(true)
        } label: {
            HStack {
                if let amount = model.amount {
                    Text(AmountText.text(amount))
                        .font(
                            .system(
                                size: 20,
                                weight: .medium,
                                design: .serif
                            )
                        )
                        .monospacedDigit()
                        .foregroundStyle(Palette.champagne)
                } else {
                    Text("毎回入れる")
                        .font(.body)
                        .foregroundStyle(Palette.dusk)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .frame(height: 46)
            .background(Palette.drawer, in: .rect(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(amountStroke, lineWidth: 1)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .animation(.snappy(duration: 0.2), value: isEnteringAmount)
    }

    var keypadDrawer: some View {
        VStack(spacing: 10) {
            Button("完了") {
                setEnteringAmount(false)
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(Palette.gold)
            .frame(minWidth: 44, minHeight: 32)
            .frame(maxWidth: .infinity, alignment: .trailing)

            Keypad(activeTax: model.calculator.taxNote?.rate) { key in
                model.press(key)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background {
            Self.drawerShape
                .fill(Palette.drawer)
                .overlay {
                    Self.drawerShape
                        .stroke(Palette.gold.opacity(0.35), lineWidth: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        }
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
        .padding(.top, 6)
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

    static let drawerShape = UnevenRoundedRectangle(
        topLeadingRadius: 28,
        topTrailingRadius: 28
    )

    static let drawerSpace: CGFloat = 340

    static let columns = Array(
        repeating: GridItem(.flexible(), spacing: 5),
        count: 5
    )

    var title: String {
        let action = model.isEditing ? "編集" : "追加"
        return "\(model.typeName)テンプレートを\(action)"
    }

    var saveColor: Color {
        model.canSave ? Palette.gold : Palette.dusk
    }

    var amountStroke: Color {
        isEnteringAmount ? Palette.gold : Palette.gold.opacity(0.35)
    }

    var bottomSpace: CGFloat {
        isEnteringAmount ? Self.drawerSpace : 8
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

    func setEnteringAmount(_ isEntering: Bool) {
        withAnimation(.snappy) {
            isEnteringAmount = isEntering
        }
    }

    func finishTyping() {
        focus = nil
        setEnteringAmount(false)
    }

    func reveal(
        _ field: Field?,
        in proxy: ScrollViewProxy
    ) {
        guard field == .memo else {
            return
        }

        Task {
            guard await (try? Task.sleep(for: .seconds(0.35))) != nil else {
                return
            }

            withAnimation(.snappy) {
                proxy.scrollTo(Field.memo, anchor: .bottom)
            }
        }
    }

    func close() {
        finishTyping()

        if model.isChanged {
            isConfirmingDiscard = true
        } else {
            dismiss()
        }
    }

    func save() async {
        finishTyping()

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
        TemplateEditSheet(
            model: TemplateEditModel(
                database: database,
                type: .expense
            )
        )
    }
}
