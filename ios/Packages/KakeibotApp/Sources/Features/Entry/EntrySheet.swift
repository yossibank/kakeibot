import Core
import DesignSystem
import Store
import SwiftUI

public struct EntrySheet: View {
    @State private var model: EntryModel
    @State private var isEnteringAmount = false
    @State private var isEditingMemo = false
    @State private var categoryPage: Int? = 0
    @State private var sheet: Sheet?
    @State private var memoChipFrame: CGRect = .zero

    @FocusState private var isMemoFocused: Bool

    @Environment(\.dismiss) private var dismiss

    public init(model: EntryModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        ZStack(alignment: .top) {
            content

            if isEditingMemo {
                memoLayer
            }
        }
        .coordinateSpace(.named(Self.coordinateSpace))
        .ignoresSafeArea(.keyboard)
        .background {
            Rectangle()
                .fill(Palette.night)
                .ignoresSafeArea()
        }
        .preferredColorScheme(.dark)
        .sheet(item: $sheet) { sheet in
            sheetContent(for: sheet)
        }
        .onChange(of: model.type) {
            categoryPage = 0
        }
        .task {
            await load()
        }
    }
}

private extension EntrySheet {
    var content: some View {
        VStack(spacing: 14) {
            header
            dial
            details
            categoryPager

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(Palette.rose)
            }

            PrimaryButton(model.saveTitle) {
                Task {
                    await save()
                }
            }
            .disabled(!model.canSave)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 8)
        .contentShape(.rect)
        .onTapGesture {
            setEnteringAmount(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            if isEnteringAmount {
                keypadDrawer
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    var header: some View {
        HStack {
            RingButton("閉じる", systemImage: "xmark") {
                dismiss()
            }

            Spacer()

            CapsulePicker(selection: typeBinding, options: Self.typeOptions)

            Spacer()

            if model.isEditing {
                RingButton(
                    "この記録を消す",
                    systemImage: "trash",
                    style: .destructive
                ) {
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
            setEnteringAmount(!isEnteringAmount)
        } label: {
            GeometryReader { proxy in
                let size = min(proxy.size.width, proxy.size.height)

                dialFace(size: size)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .buttonStyle(.plain)
        .frame(minHeight: 150, maxHeight: 270)
        .accessibilityLabel("金額")
        .accessibilityValue(AmountText.text(model.amount))
        .accessibilityHint("タップしてテンキーを開く")
    }

    var details: some View {
        HStack(spacing: 8) {
            Button {
                open(.wallet)
            } label: {
                Chip(
                    model.walletName,
                    systemImage: "wallet.bifold",
                    isHighlighted: model.walletId != nil
                )
            }

            Button {
                open(.date)
            } label: {
                Chip(
                    EntryModel.dateText(for: model.date, today: today),
                    systemImage: "calendar",
                    isHighlighted: true
                )
            }

            Button {
                editMemo(true)
            } label: {
                Chip(
                    model.memo.isEmpty ? "メモ" : model.memo,
                    systemImage: "square.and.pencil",
                    isHighlighted: !model.memo.isEmpty
                )
            }
            .layoutPriority(-1)
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .named(Self.coordinateSpace))
            } action: { frame in
                memoChipFrame = frame
            }

            Spacer(minLength: 0)
        }
        .buttonStyle(.plain)
    }

    var categoryPager: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(
                        Array(model.categoryPages.enumerated()),
                        id: \.offset
                    ) { index, page in
                        categoryGrid(page)
                            .containerRelativeFrame(.horizontal)
                            .id(index)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $categoryPage)
            .scrollIndicators(.hidden)
            .frame(minHeight: 168, maxHeight: 264)

            if model.categoryPages.count > 1 {
                PageDots(
                    count: model.categoryPages.count,
                    current: categoryPage ?? 0
                )
            }
        }
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

            PrimaryButton(model.saveTitle) {
                Task {
                    await save()
                }
            }
            .disabled(!model.canSave)
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

    @ViewBuilder
    var memoLayer: some View {
        Color.black
            .opacity(0.35)
            .ignoresSafeArea()
            .onTapGesture {
                editMemo(false)
            }
            .transition(.opacity)

        Color.clear
            .frame(height: max(memoChipFrame.minY - 10, 0))
            .overlay(alignment: .bottom) {
                EntryMemoCard(
                    model: model,
                    isFocused: $isMemoFocused,
                    pointerX: memoChipFrame.midX - Self.memoCardInset
                ) {
                    editMemo(false)
                }
                .padding(.horizontal, Self.memoCardInset)
            }
            .transition(Self.memoTransition)
    }

    func dialFace(size: CGFloat) -> some View {
        let amountScale: CGFloat = model.amount < 100_000 ? 0.2 : 0.118
        let hint = isEnteringAmount ? "入力中" : "タップして入力"
        let note = model.expressionText ?? hint

        return ZStack {
            DialFace(isActive: isEnteringAmount)

            Text(model.type == .income ? "収入" : "支出")
                .font(.system(size: 12, design: .serif))
                .tracking(5)
                .foregroundStyle(Palette.gold)
                .offset(y: -size * 0.19)

            Text(AmountText.text(model.amount))
                .font(
                    .system(
                        size: size * amountScale,
                        weight: .semibold,
                        design: .serif
                    )
                )
                .monospacedDigit()
                .foregroundStyle(Palette.champagne)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(width: size * 0.7, height: size * 0.26)

            Text(note)
                .font(.caption2)
                .foregroundStyle(Palette.mist)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: size * 0.66)
                .offset(y: size * 0.19)
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
    }

    func categoryGrid(_ page: [EntryCategory]) -> some View {
        Grid(horizontalSpacing: 6, verticalSpacing: 6) {
            ForEach(0..<Self.categoryRows, id: \.self) { row in
                GridRow {
                    ForEach(0..<Self.categoryColumns, id: \.self) { column in
                        let index = row * Self.categoryColumns + column

                        if index < page.count {
                            categoryButton(page[index])
                        } else {
                            Color.clear
                        }
                    }
                }
            }
        }
    }

    func categoryButton(_ category: EntryCategory) -> some View {
        let isSelected = model.categoryId == category.id
        let border = isSelected ? Palette.gold.opacity(0.55) : Color.clear

        return Button {
            setEnteringAmount(false)
            model.categoryId = category.id
        } label: {
            VStack(spacing: 6) {
                IconImage(model.icon(for: category), size: 20)

                Text(category.name)
                    .font(.system(size: 11))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? Palette.champagne : Palette.mist)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                isSelected ? Palette.gold.opacity(0.12) : Color.clear,
                in: .rect(cornerRadius: 14)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(border, lineWidth: 1)
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
                Task {
                    await delete()
                }
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

    static let coordinateSpace = "EntrySheet"
    static let memoCardInset: CGFloat = 12
    static let drawerShape = UnevenRoundedRectangle(
        topLeadingRadius: 28,
        topTrailingRadius: 28
    )
    static let categoryRows = 3
    static let categoryColumns = 4

    static var memoTransition: AnyTransition {
        .scale(scale: 0.92, anchor: .bottom).combined(with: .opacity)
    }

    var today: LocalDate {
        LocalDate(Date(), in: .current)
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

    func open(_ sheet: Sheet) {
        setEnteringAmount(false)
        self.sheet = sheet
    }

    func editMemo(_ isEditing: Bool) {
        setEnteringAmount(false)

        if !isEditing {
            isMemoFocused = false
        }

        withAnimation(.snappy(duration: 0.25)) {
            isEditingMemo = isEditing
        }
    }

    func setEnteringAmount(_ isEntering: Bool) {
        withAnimation(.snappy) {
            isEnteringAmount = isEntering
        }
    }

    func load() async {
        if !model.isLoaded {
            await model.load()
        }

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
