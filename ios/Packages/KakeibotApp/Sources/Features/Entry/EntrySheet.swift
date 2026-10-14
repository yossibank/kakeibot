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
    @State private var isConfirmingDiscard = false
    @State private var categoryMenu: CategoryMenu?
    @State private var pressingCategory: EntryCategory.ID?

    @AppStorage("entry.hasOpenedCategoryMenu") private var hasOpenedMenu = false
    @State private var sheetWidth: CGFloat = 0

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

            if let categoryMenu {
                categoryMenuLayer(categoryMenu)
            }
        }
        .coordinateSpace(.named(Self.coordinateSpace))
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            sheetWidth = width
        }
        .sensoryFeedback(
            .impact(weight: .medium),
            trigger: categoryMenu
        ) { _, menu in
            menu != nil
        }
        .ignoresSafeArea(.keyboard)
        .background {
            Rectangle()
                .fill(Palette.night)
                .ignoresSafeArea()
        }
        .preferredColorScheme(.dark)
        .confirmsDiscard(
            when: model.isChanged,
            isPresented: $isConfirmingDiscard
        ) {
            dismiss()
        }
        .sheet(item: $sheet, onDismiss: reloadCategories) { sheet in
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
            RingButton(systemImage: "xmark") {
                close()
            }

            Spacer()

            CapsulePicker(selection: typeBinding, options: Self.typeOptions)

            Spacer()

            if model.isEditing {
                RingButton(
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

            if !hasOpenedMenu {
                Label("長押しで直す・隠す", systemImage: "hand.tap")
                    .font(.caption2)
                    .foregroundStyle(Palette.mist)
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

    func categoryGrid(_ page: [EntryModel.CategoryCell]) -> some View {
        Grid(horizontalSpacing: 6, verticalSpacing: 6) {
            ForEach(0..<Self.categoryRows, id: \.self) { row in
                GridRow {
                    ForEach(0..<Self.categoryColumns, id: \.self) { column in
                        let index = row * Self.categoryColumns + column

                        if index < page.count {
                            categoryCell(page[index])
                        } else {
                            Color.clear
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    func categoryCell(_ cell: EntryModel.CategoryCell) -> some View {
        switch cell {
        case let .category(category):
            categoryButton(category)
        case .add:
            Button {
                open(.newCategory)
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .ultraLight))

                    Text("追加")
                        .font(.system(size: 11))
                }
                .foregroundStyle(Palette.gold)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Palette.gold.opacity(0.45), style: Self.dash)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
    }

    func categoryButton(_ category: EntryCategory) -> some View {
        let isPressing = pressingCategory == category.id
        let scale: CGFloat = isPressing ? 0.93 : 1

        return categoryFace(category, isLifted: false)
            .scaleEffect(scale)
            .animation(.snappy(duration: 0.2), value: isPressing)
            .overlay {
                GeometryReader { proxy in
                    Color.clear
                        .contentShape(.rect)
                        .onTapGesture {
                            select(category)
                        }
                        .onLongPressGesture(
                            minimumDuration: Self.menuPressDuration
                        ) {
                            let space = CoordinateSpace.named(
                                Self.coordinateSpace
                            )

                            openMenu(for: category, at: proxy.frame(in: space))
                        } onPressingChanged: { isPressing in
                            pressingCategory = isPressing ? category.id : nil
                        }
                }
            }
    }

    func categoryFace(
        _ category: EntryCategory,
        isLifted: Bool
    ) -> some View {
        let isSelected = model.categoryId == category.id
        let isLit = isSelected || isLifted
        let color = isLit ? Palette.champagne : Palette.mist
        let fill = isLifted ? Palette.drawer : Self.categoryFill(isLit)
        let border = isLit ? Palette.gold.opacity(0.55) : Color.clear
        let width: CGFloat = isLifted ? 1.2 : 1

        return VStack(spacing: 6) {
            IconImage(model.icon(for: category), size: 20)

            Text(category.name)
                .font(.system(size: 11))
                .lineLimit(1)
        }
        .foregroundStyle(color)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(fill, in: .rect(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(border, lineWidth: width)
        }
        .contentShape(.rect)
    }

    @ViewBuilder
    func categoryMenuLayer(_ menu: CategoryMenu) -> some View {
        Color.black
            .opacity(0.45)
            .ignoresSafeArea()
            .onTapGesture {
                closeCategoryMenu()
            }
            .transition(.opacity)

        categoryFace(menu.category, isLifted: true)
            .frame(width: menu.frame.width, height: menu.frame.height)
            .scaleEffect(1.06)
            .shadow(color: Palette.gold.opacity(0.35), radius: 12)
            .position(x: menu.frame.midX, y: menu.frame.midY)
            .allowsHitTesting(false)
            .transition(.opacity)

        Color.clear
            .frame(height: max(menu.frame.minY - 12, 0))
            .frame(maxWidth: .infinity)
            .overlay(alignment: .bottomLeading) {
                EntryCategoryMenu(
                    icon: model.icon(for: menu.category),
                    name: menu.category.name,
                    onEdit: {
                        closeCategoryMenu()
                        open(.editCategory(menu.category))
                    },
                    onHide: {
                        closeCategoryMenu()

                        Task {
                            await model.hideCategory(menu.category)
                        }
                    }
                )
                .offset(x: menuX(for: menu))
            }
            .transition(Self.memoTransition)
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
        case .newCategory:
            CategoryEditSheet(model: model.newCategoryModel()) { category in
                Task {
                    await addCategory(category)
                }
            }
        case let .editCategory(category):
            CategoryEditSheet(model: model.editCategoryModel(category))
        }
    }
}

private extension EntrySheet {
    struct CategoryMenu: Equatable {
        let category: EntryCategory
        let frame: CGRect
    }

    enum Sheet: Hashable, Identifiable {
        case wallet
        case date
        case delete
        case newCategory
        case editCategory(EntryCategory)

        var id: Self {
            self
        }
    }

    static let typeOptions: [CapsulePicker<Entry.Kind>.Option] = [
        .init("支出", value: .expense),
        .init("収入", value: .income)
    ]

    nonisolated static let coordinateSpace = "EntrySheet"
    static let memoCardInset: CGFloat = 12
    static let drawerShape = UnevenRoundedRectangle(
        topLeadingRadius: 28,
        topTrailingRadius: 28
    )
    static let categoryRows = 3
    static let categoryColumns = 4
    static let dash = StrokeStyle(lineWidth: 1, dash: [4, 3])
    static let menuPressDuration = 0.25

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

    func close() {
        if model.isChanged {
            isConfirmingDiscard = true
        } else {
            dismiss()
        }
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

        showSelectedCategory()
    }

    func showSelectedCategory() {
        let page = model.categoryPages.firstIndex { page in
            page.contains { $0.categoryId == model.categoryId }
        }

        categoryPage = page ?? 0
    }

    static func categoryFill(_ isSelected: Bool) -> Color {
        isSelected ? Palette.gold.opacity(0.12) : Color.clear
    }

    func menuX(for menu: CategoryMenu) -> CGFloat {
        let width = EntryCategoryMenu.width
        let inset = Self.memoCardInset
        let preferred = menu.frame.midX - width / 2
        return min(max(preferred, inset), sheetWidth - width - inset)
    }

    func select(_ category: EntryCategory) {
        setEnteringAmount(false)
        model.categoryId = category.id
    }

    func openMenu(
        for category: EntryCategory,
        at frame: CGRect
    ) {
        setEnteringAmount(false)
        pressingCategory = nil
        hasOpenedMenu = true

        withAnimation(.snappy(duration: 0.25)) {
            categoryMenu = CategoryMenu(category: category, frame: frame)
        }
    }

    func closeCategoryMenu() {
        withAnimation(.snappy(duration: 0.2)) {
            categoryMenu = nil
        }
    }

    func reloadCategories() {
        Task {
            await model.reloadCategories()
        }
    }

    func addCategory(_ category: EntryCategory) async {
        await model.reloadCategories(selecting: category.id)

        withAnimation(.snappy) {
            showSelectedCategory()
        }
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
