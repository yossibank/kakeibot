import Core
import DesignSystem
import FeatureModels
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
                selection: model.state.category.tagId,
                onSelect: { id in
                    model.state.toggleTag(id)
                },
                onAdd: {
                    editTags()
                },
                onEdit: tagEditAction
            )

            if model.output.amount > 0 {
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
    func categoryMenuLayer(
        _ category: EntryCategory,
        at frame: CGRect
    ) -> some View {
        Scrim(.menu)
            .ignoresSafeArea()
            .onTapGesture {
                closeCategoryMenu()
            }
            .transition(.opacity)

        EntryCategoryFace(
            category: category,
            icon: model.output.icon(for: category),
            isLit: true,
            isLifted: true
        )
        .frame(width: frame.width, height: frame.height)
        .scaleEffect(1.06)
        .glow(Palette.glow.opacity(.muted), radius: 12)
        .position(x: frame.midX, y: frame.midY)
        .allowsHitTesting(false)
        .transition(.opacity)

        Color.clear
            .frame(height: max(frame.minY - 12, 0))
            .frame(maxWidth: .infinity)
            .overlay(alignment: .bottomLeading) {
                EntryCategoryMenu(
                    icon: model.output.icon(for: category),
                    name: category.name,
                    onEdit: {
                        closeCategoryMenu()
                        open(.editCategory(category))
                    },
                    onHide: {
                        closeCategoryMenu()

                        model.perform {
                            await $0.hideCategory(category)
                        }
                    }
                )
                .offset(x: menuX(for: frame))
            }
            .transition(Self.menuTransition)
    }

    func useTemplate(_ template: EntryTemplate) {
        withAnimation(.snappy) {
            model.apply(template)
            model.showSelectedCategory()
        }

        if template.amount == nil {
            show(.amount)
        }
    }
}

private extension EntrySheet {
    var categoryPager: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(
                        Array(model.output.categoryPages.enumerated()),
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
            .scrollPosition(id: categoryPageBinding)
            .scrollIndicators(.hidden)
            .frame(height: Self.pagerHeight + Self.liftInset * 2)
            .padding(-Self.liftInset)
            .id(model.state.type)

            if model.output.categoryPages.count > 1 {
                PageDots(
                    count: model.output.categoryPages.count,
                    current: model.state.screen.categoryPage ?? 0
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
            EntryCategoryTile(
                category: category,
                icon: model.output.icon(for: category),
                isSelected: model.state.category.id == category.id
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

    var categoryPageBinding: Binding<Int?> {
        Binding {
            model.state.screen.categoryPage
        } set: { page in
            model.state.showCategoryPage(page)
        }
    }

    var tagEditAction: (() -> Void)? {
        guard
            let category = model.output.selectedCategory,
            !model.output.tags.isEmpty
        else {
            return nil
        }

        return {
            open(.editCategory(category))
        }
    }

    var tagItems: [TagLine<EntryTag.ID>.Item] {
        model.output.tags.map { TagLine.Item(id: $0.id, name: $0.name) }
    }

    func editTags() {
        guard let category = model.output.selectedCategory else {
            return
        }

        open(.addTag(category))
    }

    func menuX(for frame: CGRect) -> CGFloat {
        let width = EntryCategoryMenu.width
        let inset = Self.menuInset
        let preferred = frame.midX - width / 2
        return min(max(preferred, inset), layout.sheetWidth - width - inset)
    }

    func select(_ category: EntryCategory) {
        model.state.setCategory(category.id)
        show(.amount)
    }

    func openMenu(
        for category: EntryCategory,
        at frame: CGRect
    ) {
        withAnimation(.snappy(duration: 0.25)) {
            layout.menuFrame = frame
            model.state.openMenu(for: category)
        }
    }

    func closeCategoryMenu() {
        withAnimation(.snappy(duration: 0.2)) {
            model.state.closeMenu()
        }
    }
}
