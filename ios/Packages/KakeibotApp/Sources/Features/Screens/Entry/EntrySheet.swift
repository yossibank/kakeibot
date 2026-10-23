import Core
import DesignSystem
import Store
import SwiftUI

public struct EntrySheet: View {
    @State private var model: EntryModel
    @State private var isEnteringAmount = false
    @State private var isEditingMemo = false
    @State private var isPeekingMemo = false
    @State private var categoryPage: Int? = 0
    @State private var sheet: Sheet?
    @State private var memoChipFrame: CGRect = .zero
    @State private var isConfirmingDiscard = false
    @State private var categoryMenu: CategoryMenu?
    @State private var pressingCategory: EntryCategory.ID?
    @State private var sheetWidth: CGFloat = 0
    @State private var drawerHeight: CGFloat = 0
    @State private var deletion: Deletion?

    @FocusState private var isMemoFocused: Bool

    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeStyle.corner) private var corner

    private let onChange: (EntryChange) -> Void

    public init(
        model: EntryModel,
        onChange: @escaping (EntryChange) -> Void = { _ in }
    ) {
        _model = State(initialValue: model)
        self.onChange = onChange
    }

    public var body: some View {
        GeometryReader { _ in
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
            .errorBanner(
                model.errorNotice,
                bottom: bannerBottom
            ) {
                model.errorNotice.clear()
            }
            .deletionNotice($deletion, bottom: bannerBottom) { deletion in
                Task {
                    await model.restore(deletion)
                }
            }
            .background {
                Rectangle()
                    .fill(Palette.background)
                    .ignoresSafeArea()
            }
            .confirmsDiscard(
                when: model.isChanged,
                isPresented: $isConfirmingDiscard
            ) {
                dismiss()
            }
            .sheet(item: $sheet, onDismiss: reloadCategories) { sheet in
                sheetContent(for: sheet)
            }
            .task {
                await load()
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

extension EntrySheet {
    static func categoryFill(_ isSelected: Bool) -> Color {
        isSelected ? Palette.accent.opacity(.subtle) : Color.clear
    }
}

private extension EntrySheet {
    var content: some View {
        VStack(spacing: 14) {
            header

            ViewThatFits(in: .vertical) {
                form

                ScrollView {
                    form
                        .padding(.vertical, Self.fade)
                }
                .scrollIndicators(.hidden)
                .edgeFade(Self.fade)
                .padding(.vertical, -Self.fade)
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

    var form: some View {
        VStack(spacing: 14) {
            dial
            details

            if model.type == .transfer {
                ZStack(alignment: .top) {
                    categoryArea
                        .hidden()

                    VStack(spacing: 12) {
                        EntryTransferPanel(model: model) { role in
                            open(.wallet(role))
                        }

                        if let remaining = model.loanRemaining,
                           remaining != model.amount {
                            payOffButton(remaining)
                        }
                    }
                }
            } else {
                categoryArea
            }
        }
    }

    var categoryArea: some View {
        VStack(spacing: 14) {
            EntryTemplateRow(
                model: model,
                onUse: { template in
                    useTemplate(template)
                },
                onAdd: {
                    open(.newTemplate)
                }
            )

            categoryPager

            TagLine(tagItems, selection: model.tagId) { id in
                model.toggleTag(id)
            } onAdd: {
                editTags()
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
                    style: .destructive,
                    label: "削除"
                ) {
                    Task {
                        await delete()
                    }
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

                EntryDialFace(
                    model: model,
                    isActive: isEnteringAmount,
                    size: size
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .buttonStyle(.plain)
        .frame(minHeight: Self.dialMinSize, maxHeight: 270)
    }

    var details: some View {
        HStack(spacing: 8) {
            if model.type != .transfer {
                Button {
                    open(.wallet(.source))
                } label: {
                    Chip(
                        model.walletName,
                        systemImage: "wallet.bifold",
                        isHighlighted: model.walletId != nil
                    )
                }
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
                if !isPeekingMemo {
                    editMemo(true)
                }
            } label: {
                ViewThatFits(in: .horizontal) {
                    Chip(
                        memoTitle,
                        systemImage: "square.and.pencil",
                        isHighlighted: !model.memo.isEmpty
                    )

                    Chip(
                        "",
                        systemImage: "square.and.pencil",
                        isHighlighted: !model.memo.isEmpty
                    )
                }
            }
            .simultaneousGesture(memoPeekGesture)
            .background {
                Color.clear
                    .popover(isPresented: $isPeekingMemo) {
                        memoPeek
                    }
            }
            .sensoryFeedback(.impact(weight: .light), trigger: isPeekingMemo)
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

    var memoPeek: some View {
        Text(model.memo)
            .textFont(.footnote)
            .foregroundStyle(Palette.text)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: Self.peekWidth, alignment: .leading)
            .padding(14)
            .presentationCompactAdaptation(.popover)
            .presentationBackground(Palette.panel)
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
            .frame(height: Self.pagerHeight)
            .id(model.type)

            PageDots(
                count: model.categoryPages.count,
                current: categoryPage ?? 0
            )

            if !model.hasOpenedCategoryMenu {
                Label("長押しで編集・非表示", systemImage: "hand.tap")
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)
            }
        }
    }

    var keypadDrawer: some View {
        VStack(spacing: 10) {
            RingButton(systemImage: "checkmark", style: .prominent) {
                setEnteringAmount(false)
            }
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
                .fill(Palette.panel)
                .overlay {
                    Self.drawerShape
                        .stroke(Palette.accent.opacity(.muted), lineWidth: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { height in
            drawerHeight = height
        }
    }

    @ViewBuilder
    var memoLayer: some View {
        Palette.scrim
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

    func payOffButton(_ remaining: Int) -> some View {
        Button {
            withAnimation(.snappy) {
                model.payOffLoan()
            }
        } label: {
            Label(
                "残り \(AmountText.text(remaining)) をまとめて返す",
                systemImage: "checkmark.seal"
            )
            .textFont(.footnote)
            .foregroundStyle(Palette.accent)
            .padding(.horizontal, 16)
            .frame(minHeight: 40)
            .overlay {
                Capsule()
                    .stroke(Palette.accent.opacity(.medium), lineWidth: 1)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .transition(.opacity)
    }

    func categoryGrid(_ page: [EntryModel.CategoryCell]) -> some View {
        Grid(
            horizontalSpacing: Self.categorySpacing,
            verticalSpacing: Self.categorySpacing
        ) {
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
                VStack(spacing: 4) {
                    Image(systemName: "plus")
                        .sansFont(.body, weight: .ultraLight)

                    Text("追加")
                        .textFont(size: .caption)
                }
                .foregroundStyle(Palette.accent)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay {
                    RoundedRectangle(cornerRadius: corner.radius(12))
                        .stroke(Palette.accent.opacity(.medium), style: .dashed)
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
        let color = isLit ? Palette.accentStrong : Palette.subtext
        let fill = isLifted ? Palette.panel : Self.categoryFill(isLit)
        let border = isLit ? Palette.outline : Color.clear
        let width: CGFloat = isLifted ? 1.2 : 1

        return VStack(spacing: 4) {
            IconImage(model.icon(for: category), size: 17)

            Text(category.name)
                .textFont(size: .caption)
                .lineLimit(1)
        }
        .foregroundStyle(color)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(fill, in: .rect(cornerRadius: corner.radius(12)))
        .overlay {
            RoundedRectangle(cornerRadius: corner.radius(12))
                .stroke(border, lineWidth: width)
        }
        .contentShape(.rect)
    }

    @ViewBuilder
    func categoryMenuLayer(_ menu: CategoryMenu) -> some View {
        Palette.scrim
            .opacity(0.45)
            .ignoresSafeArea()
            .onTapGesture {
                closeCategoryMenu()
            }
            .transition(.opacity)

        categoryFace(menu.category, isLifted: true)
            .frame(width: menu.frame.width, height: menu.frame.height)
            .scaleEffect(1.06)
            .shadow(color: Palette.glow.opacity(.muted), radius: 12)
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
        case let .wallet(role):
            EntryWalletSheet(model: model, role: role)
        case .date:
            EntryDateSheet(model: model, today: today)
        case .newCategory:
            CategoryEditSheet(model: model.newCategoryModel()) { category in
                Task {
                    await addCategory(category)
                }
            }
        case let .editCategory(category):
            CategoryEditSheet(model: model.editCategoryModel(category)) { _ in
            } onDelete: { deletion in
                self.deletion = deletion
            }
        case let .addTag(category):
            CategoryEditSheet(
                model: model.editCategoryModel(category),
                startsAddingTag: true
            )
        case .newTemplate:
            TemplateEditSheet(model: model.newTemplateModel())
        }
    }
}

private extension EntrySheet {
    struct CategoryMenu: Equatable {
        let category: EntryCategory
        let frame: CGRect
    }

    enum Sheet: Hashable, Identifiable {
        case wallet(EntryWalletSheet.Role)
        case date
        case newCategory
        case editCategory(EntryCategory)
        case addTag(EntryCategory)
        case newTemplate

        var id: Self {
            self
        }
    }

    static let typeOptions: [CapsulePicker<Entry.Kind>.Option] = [
        .init("支出", value: .expense),
        .init("収入", value: .income),
        .init("振替", value: .transfer)
    ]

    nonisolated static let coordinateSpace = "EntrySheet"
    static let memoCardInset: CGFloat = 12
    static let drawerShape = UnevenRoundedRectangle(
        topLeadingRadius: 28,
        topTrailingRadius: 28
    )
    static let dialMinSize: CGFloat = 240
    static let fade: CGFloat = 20
    static let categoryRows = 3
    static let categoryColumns = 5
    static let categorySpacing: CGFloat = 5
    static let categoryHeight: CGFloat = 54
    static let menuPressDuration = 0.15
    static let peekDuration = 0.35
    static let peekWidth: CGFloat = 260

    static var pagerHeight: CGFloat {
        let rows = CGFloat(categoryRows)
        return categoryHeight * rows + categorySpacing * (rows - 1)
    }

    static var memoTransition: AnyTransition {
        .scale(scale: 0.92, anchor: .bottom).combined(with: .opacity)
    }

    var bannerBottom: CGFloat {
        isEnteringAmount ? drawerHeight + 10 : 12
    }

    var today: LocalDate {
        LocalDate(Date(), in: .current)
    }

    var memoPeekGesture: some Gesture {
        LongPressGesture(minimumDuration: Self.peekDuration)
            .onEnded { _ in
                isPeekingMemo = !model.memo.isEmpty
            }
    }

    var memoTitle: String {
        model.memo.isEmpty ? "メモ" : model.memo
    }

    var tagItems: [TagLine<EntryTag.ID>.Item] {
        model.tags.map { TagLine.Item(id: $0.id, name: $0.name) }
    }

    var typeBinding: Binding<Entry.Kind> {
        Binding(
            get: {
                model.type
            },
            set: { type in
                var transaction = Transaction()
                transaction.disablesAnimations = true

                withTransaction(transaction) {
                    model.select(type)
                    showSelectedCategory()
                }
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

    func editTags() {
        guard let category = model.selectedCategory else {
            return
        }

        open(.addTag(category))
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

        isEnteringAmount = model.opensKeypadFirst

        showSelectedCategory()
    }

    func showSelectedCategory() {
        let page = model.categoryPages.firstIndex { page in
            page.contains { $0.categoryId == model.categoryId }
        }

        categoryPage = page ?? 0
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

        Task {
            await model.markCategoryMenuOpened()
        }

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
            await model.reloadTemplates()
        }
    }

    func useTemplate(_ template: EntryTemplate) {
        withAnimation(.snappy) {
            model.apply(template)
            showSelectedCategory()
        }

        setEnteringAmount(template.amount == nil)
    }

    func addCategory(_ category: EntryCategory) async {
        await model.reloadCategories(selecting: category.id)

        withAnimation(.snappy) {
            showSelectedCategory()
        }
    }

    func save() async {
        guard let change = await model.save() else {
            return
        }

        onChange(change)
        dismiss()
    }

    func delete() async {
        guard let change = await model.delete() else {
            return
        }

        onChange(change)
        dismiss()
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
