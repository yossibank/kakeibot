import Core
import DesignSystem
import Store
import SwiftUI

public struct EntrySheet: View {
    @State private var model: EntryModel
    @State private var isEnteringAmount: Bool
    @State private var categoryPage = 0
    @State private var sheet: Sheet?

    @FocusState private var isMemoFocused: Bool

    @Environment(\.dismiss) private var dismiss

    public init(model: EntryModel) {
        _model = State(initialValue: model)
        _isEnteringAmount = State(initialValue: !model.isEditing)
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 18)

            ScrollView {
                VStack(spacing: 18) {
                    dial
                    details

                    TextField(
                        "メモ",
                        text: $model.memo,
                        prompt: Text("メモ").foregroundStyle(Palette.dusk),
                        axis: .vertical
                    )
                    .lineLimit(1...4)
                    .font(.subheadline)
                    .foregroundStyle(Palette.ink)
                    .tint(Palette.gold)
                    .focused($isMemoFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isMemoFocused ? Palette.gold.opacity(0.6) : Palette.line,
                                lineWidth: 1
                            )
                    }

                    categoryPager
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomPanel
        }
        .background(Palette.night.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button("完了") { isMemoFocused = false }
            }
        }
        .sheet(item: $sheet) { sheet in
            sheetContent(for: sheet)
        }
        .onChange(of: model.type) {
            categoryPage = 0
        }
        .onChange(of: isMemoFocused) { _, isFocused in
            if isFocused {
                setEnteringAmount(false)
            }
        }
        .task { await load() }
    }
}

private extension EntrySheet {
    var header: some View {
        HStack {
            RingButton("閉じる", systemImage: "xmark") {
                dismiss()
            }

            Spacer()

            CapsulePicker(selection: typeBinding, options: Self.typeOptions)

            Spacer()

            if model.isEditing {
                RingButton("この記録を消す", systemImage: "trash", style: .destructive) {
                    open(.delete)
                }
            } else {
                Color.clear
                    .frame(width: 44, height: 44)
            }
        }
    }

    var dial: some View {
        Button {
            isMemoFocused = false
            setEnteringAmount(!isEnteringAmount)
        } label: {
            ZStack {
                DialFace(isActive: isEnteringAmount)

                Text(model.type == .income ? "収入" : "支出")
                    .font(.system(size: 12, design: .serif))
                    .tracking(5)
                    .foregroundStyle(Palette.gold)
                    .offset(y: -46)

                Text(AmountText.text(model.amount))
                    .font(.system(size: amountFontSize, weight: .semibold, design: .serif))
                    .monospacedDigit()
                    .foregroundStyle(Palette.champagne)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .frame(width: 164, height: 60)

                Text(isEnteringAmount ? "入力中" : "タップして入力")
                    .font(.caption2)
                    .foregroundStyle(Palette.mist)
                    .offset(y: 46)
            }
            .frame(width: 236, height: 236)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("金額")
        .accessibilityValue(AmountText.text(model.amount))
        .accessibilityHint("タップしてテンキーを開く")
    }

    var details: some View {
        HStack(spacing: 8) {
            Button {
                open(.wallet)
            } label: {
                Chip(model.walletName, systemImage: "wallet.bifold")
            }

            Button {
                open(.date)
            } label: {
                Chip(EntryModel.dateText(for: model.date, today: today), systemImage: "calendar")
            }

            Spacer(minLength: 0)
        }
        .buttonStyle(.plain)
    }

    var categoryPager: some View {
        VStack(spacing: 10) {
            TabView(selection: $categoryPage) {
                ForEach(Array(model.categoryPages.enumerated()), id: \.offset) { index, page in
                    LazyVGrid(columns: Self.categoryColumns, spacing: 6) {
                        ForEach(page) { category in
                            categoryButton(category)
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 3 * Self.categoryHeight + 2 * 6)

            PageDots(count: model.categoryPages.count, current: categoryPage)
        }
    }

    var bottomPanel: some View {
        VStack(spacing: 12) {
            if isEnteringAmount {
                VStack(spacing: 4) {
                    Capsule()
                        .fill(Palette.line)
                        .frame(width: 36, height: 4)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .overlay(alignment: .trailing) {
                            Button("完了") { setEnteringAmount(false) }
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Palette.gold)
                                .frame(minWidth: 44, minHeight: 36)
                        }

                    Keypad { model.press($0) }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(Palette.rose)
            }

            PrimaryButton(model.saveTitle) {
                Task { await save() }
            }
            .disabled(!model.canSave)
        }
        .padding(.horizontal, 20)
        .padding(.top, isEnteringAmount ? 8 : 16)
        .padding(.bottom, 8)
        .background { panelBackground }
    }

    @ViewBuilder
    var panelBackground: some View {
        if isEnteringAmount {
            UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                .fill(Palette.drawer)
                .overlay {
                    UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                        .stroke(Palette.gold.opacity(0.35), lineWidth: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        } else {
            LinearGradient(
                colors: [Palette.nightBottom.opacity(0), Palette.nightBottom],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.35)
            )
            .ignoresSafeArea(edges: .bottom)
        }
    }

    func categoryButton(_ category: EntryCategory) -> some View {
        let isSelected = model.categoryId == category.id

        return Button {
            isMemoFocused = false
            model.categoryId = category.id
        } label: {
            VStack(spacing: 6) {
                IconImage(model.icon(for: category), size: 20)

                Text(category.name)
                    .font(.system(size: 11))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? Palette.champagne : Palette.mist)
            .frame(maxWidth: .infinity, minHeight: Self.categoryHeight)
            .background(
                isSelected ? Palette.gold.opacity(0.12) : Color.clear,
                in: .rect(cornerRadius: 14)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Palette.gold.opacity(0.55) : Color.clear, lineWidth: 1)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    func sheetContent(for sheet: Sheet) -> some View {
        switch sheet {
        case .wallet:
            EntryWalletSheet(model: model)
        case .date:
            EntryDateSheet(model: model, today: today)
        case .delete:
            EntryDeleteSheet(model: model, today: today) {
                Task { await delete() }
            }
        }
    }
}

private extension EntrySheet {
    enum Sheet: Identifiable {
        case wallet
        case date
        case delete

        var id: Self {
            self
        }
    }

    static let typeOptions: [CapsulePicker<Entry.Kind>.Option] = [
        .init("支出", value: .expense),
        .init("収入", value: .income)
    ]

    static let categoryHeight: CGFloat = 64
    static let categoryColumns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 4)

    var today: LocalDate {
        LocalDate(Date(), in: .current)
    }

    var amountFontSize: CGFloat {
        model.amount < 100_000 ? 48 : 28
    }

    var typeBinding: Binding<Entry.Kind> {
        Binding(
            get: { model.type },
            set: { model.select($0) }
        )
    }

    func open(_ sheet: Sheet) {
        isMemoFocused = false
        self.sheet = sheet
    }

    func setEnteringAmount(_ isEntering: Bool) {
        withAnimation(.snappy) {
            isEnteringAmount = isEntering
        }
    }

    func load() async {
        await model.load()
        let page = model.categoryPages.firstIndex { page in
            page.contains { $0.id == model.categoryId }
        }

        categoryPage = page ?? 0
    }

    func save() async {
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

#Preview {
    let database = try? AppDatabase.inMemory()
    let today = LocalDate(Date(), in: .current)

    if let database {
        let _ = try? database.insertDefaultsIfEmpty(at: Date())
        EntrySheet(model: EntryModel(database: database, date: today))
    }
}
