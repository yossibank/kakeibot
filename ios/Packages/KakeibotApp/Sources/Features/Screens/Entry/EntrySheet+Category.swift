import Core
import DesignSystem
import SwiftUI

extension EntrySheet {
    var categoryArea: some View {
        VStack(spacing: 16) {
            categoryPager

            TagLine(
                tagItems,
                selection: model.tagId,
                onSelect: { id in
                    model.toggleTag(id)
                },
                onAdd: {
                    editTags()
                },
                onEdit: tagEditAction
            )

            EntryTemplateRow(
                model: model,
                isCompact: false,
                onUse: { template in
                    useTemplate(template)
                },
                onAdd: {
                    open(.newTemplate)
                }
            )
        }
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
            .sharesTextScale(id: menu.category)
            .frame(width: menu.frame.width, height: menu.frame.height)
            .scaleEffect(1.06)
            .glow(Palette.glow.opacity(.muted), radius: 12)
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
                            hiddenCategory = await model.hideCategory(menu.category)
                        }
                    }
                )
                .offset(x: menuX(for: menu))
            }
            .transition(Self.menuTransition)
    }
}

extension EntrySheet {
    struct CategoryMenu: Equatable {
        let category: EntryCategory
        let frame: CGRect
    }

    func showSelectedCategory() {
        let page = model.categoryPages.firstIndex { page in
            page.contains { $0.categoryId == model.categoryId }
        }

        categoryPage = page ?? 0
    }

    func useTemplate(_ template: EntryTemplate) {
        withAnimation(.snappy) {
            model.apply(template)
            showSelectedCategory()
        }

        setEnteringAmount(template.amount == nil)
    }

    func reloadCategories() {
        Task {
            await model.reloadCategories()
            await model.reloadTemplates()
        }
    }

    func addCategory(_ category: EntryCategory) async {
        await model.reloadCategories(selecting: category.id)

        withAnimation(.snappy) {
            showSelectedCategory()
        }
    }
}

private extension EntrySheet {
    var categoryPager: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(
                        Array(model.categoryPages.enumerated()),
                        id: \.offset
                    ) { index, page in
                        categoryGrid(page)
                            .padding(Self.liftInset)
                            .containerRelativeFrame(.horizontal)
                            .id(index)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $categoryPage)
            .scrollIndicators(.hidden)
            .frame(height: Self.pagerHeight + Self.liftInset * 2)
            .padding(-Self.liftInset)
            .id(model.type)

            if model.categoryPages.count > 1 {
                PageDots(
                    count: model.categoryPages.count,
                    current: categoryPage ?? 0
                )
            }
        }
    }

    func dashedCell(
        _ title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .sansFont(.body, weight: .ultraLight)

                Text(title)
                    .textFont(size: .caption)
            }
            .foregroundStyle(Palette.accent)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                RoundedRectangle(cornerRadius: corner.radius(12))
                    .stroke(Palette.accent.opacity(.medium), style: .dashed)
            }
            .padding(Self.actionInset)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
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
        .sharesTextScale(id: page)
    }

    @ViewBuilder
    func categoryCell(_ cell: EntryModel.CategoryCell) -> some View {
        switch cell {
        case let .category(category):
            categoryButton(category)
        case .add:
            dashedCell("追加", systemImage: "plus") {
                open(.newCategory)
            }
        case .edit:
            dashedCell("編集", systemImage: "gearshape") {
                open(.categories)
            }
        }
    }

    func categoryButton(_ category: EntryCategory) -> some View {
        let isPressing = pressingCategory == category.id
        let isSelected = model.categoryId == category.id
        let restingScale = isSelected ? Self.selectedScale : 1
        let scale = isPressing ? 0.93 : restingScale
        let glow = isSelected ? Palette.glow.opacity(.muted) : Color.clear

        return categoryFace(category, isLifted: false)
            .glow(glow, radius: 8)
            .scaleEffect(scale)
            .animation(.snappy(duration: 0.2), value: isPressing)
            .animation(.snappy(duration: 0.25), value: isSelected)
            .overlay {
                GeometryReader { proxy in
                    Color.clear
                        .contentShape(.rect)
                        .onTapGesture {
                            select(category)
                        }
                        .onLongPressGesture(minimumDuration: Self.menuPressDuration) {
                            let space = CoordinateSpace.named(Self.coordinateSpace)

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
        let iconSize: CGFloat = isLit ? 19 : 17

        return VStack(spacing: 4) {
            IconImage(model.icon(for: category), size: iconSize)

            Text(category.name)
                .textFont(size: .caption)
                .sharedTextScale()
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
}

private extension EntrySheet {
    static let categoryRows = 3
    static let categoryColumns = 5
    static let categorySpacing: CGFloat = 4
    static let categoryHeight: CGFloat = 54
    static let selectedScale: CGFloat = 1.05
    static let actionInset: CGFloat = 4
    static let menuPressDuration = 0.4

    static var pagerHeight: CGFloat {
        let rows = CGFloat(categoryRows)

        return categoryHeight * rows + categorySpacing * (rows - 1)
    }

    var tagEditAction: (() -> Void)? {
        guard
            let category = model.selectedCategory,
            !model.tags.isEmpty
        else {
            return nil
        }

        return {
            open(.editCategory(category))
        }
    }

    var tagItems: [TagLine<EntryTag.ID>.Item] {
        model.tags.map { TagLine.Item(id: $0.id, name: $0.name) }
    }

    func editTags() {
        guard let category = model.selectedCategory else {
            return
        }

        open(.addTag(category))
    }

    func menuX(for menu: CategoryMenu) -> CGFloat {
        let width = EntryCategoryMenu.width
        let inset = Self.menuInset
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

        withAnimation(.snappy(duration: 0.25)) {
            categoryMenu = CategoryMenu(category: category, frame: frame)
        }
    }

    func closeCategoryMenu() {
        withAnimation(.snappy(duration: 0.2)) {
            categoryMenu = nil
        }
    }
}
