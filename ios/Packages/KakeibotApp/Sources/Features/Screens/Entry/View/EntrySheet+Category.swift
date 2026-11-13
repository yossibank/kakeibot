import Core
import DesignSystem
import SwiftUI

extension EntrySheet {
    var categoryArea: some View {
        VStack(spacing: 12) {
            categoryPager

            tagAndTemplates
        }
    }

    var tagAndTemplates: some View {
        VStack(alignment: .leading, spacing: 12) {
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

            if model.amount > 0 {
                ChipButton(
                    "今の入力を保存",
                    systemImage: "plus",
                    outline: .dashed
                ) {
                    open(.newTemplate)
                }
            }
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

        EntryCategoryFace(
            category: menu.category,
            icon: model.icon(for: menu.category),
            isLit: true,
            isLifted: true
        )
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

        if template.amount == nil {
            show(.amount)
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
    }

    @ViewBuilder
    func categoryCell(_ cell: EntryModel.CategoryCell) -> some View {
        switch cell {
        case let .category(category):
            EntryCategoryCell(
                category: category,
                icon: model.icon(for: category),
                isSelected: model.categoryId == category.id
            ) {
                select(category)
            } onMenu: { frame in
                openMenu(for: category, at: frame)
            }
            .equatable()

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
}

private extension EntrySheet {
    static let categoryRows = 3
    static let categoryColumns = 5
    static let categorySpacing: CGFloat = 4
    static let categoryHeight: CGFloat = 54
    static let actionInset: CGFloat = 4

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
        model.categoryId = category.id
    }

    func openMenu(
        for category: EntryCategory,
        at frame: CGRect
    ) {
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
