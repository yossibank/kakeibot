import Core
import DesignSystem
import Store
import SwiftUI

struct RecordsFilterSheet: View {
    @Bindable var model: RecordsModel

    @State private var tab: Tab = .expense

    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeStyle.corner) private var corner

    var body: some View {
        VStack(spacing: 20) {
            header

            CapsulePicker(selection: $tab, options: tabOptions)

            if isEmpty {
                Text(emptyText)
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                ScrollView {
                    if tab == .tag {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(tagGroups) { group in
                                tagGroup(group)
                            }
                        }
                        .padding(.vertical, 4)
                    } else {
                        LazyVGrid(columns: Self.columns, spacing: 12) {
                            ForEach(items(in: tab)) { item in
                                choice(item)
                            }
                        }
                        .padding(.vertical, 4)
                        .sharesTextScale(id: items(in: tab).map(\.name))
                    }
                }
                .scrollIndicators(.hidden)
            }

            Spacer(minLength: 0)

            footer
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            Backdrop()
                .ignoresSafeArea()
        }
        .haptic(.selection, trigger: filter)
        .presentationDetents([.medium, .large])
    }
}

private extension RecordsFilterSheet {
    enum Tab: Hashable {
        case expense
        case income
        case wallet
        case tag
    }

    struct Item: Identifiable {
        let id: AnyHashable
        let name: String
        let icon: Icon?
        let isOn: Bool
        let toggle: () -> Void
    }

    struct TagGroup: Identifiable {
        let category: EntryCategory
        let icon: Icon?
        let tags: [TagLine<EntryTag.ID>.Item]

        var id: EntryCategory.ID {
            category.id
        }
    }

    var header: some View {
        HStack {
            RingButton(systemImage: "xmark") {
                dismiss()
            }
            .frame(width: Self.sideWidth, alignment: .leading)

            Spacer()

            SheetTitle("絞り込む")

            Spacer()

            Color.clear
                .frame(width: Self.sideWidth, height: 1)
        }
    }

    var footer: some View {
        HStack(spacing: 8) {
            if !filter.isEmpty {
                RecordsFilterClearButton {
                    withAnimation(.snappy) {
                        filter = EntryFilter()
                    }
                }
                .transition(.opacity)
            }

            PrimaryButton(showTitle) {
                dismiss()
            }
        }
    }

    func tagGroup(_ group: TagGroup) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                IconBadge(group.icon, size: 22)

                Text(group.category.name)
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
            }
            .padding(.leading, 8)

            TagRows(group.tags, selection: filter.tagIds) { id in
                withAnimation(.snappy) {
                    toggle(id, in: \.tagIds)
                }
            }
        }
    }

    func choice(_ item: Item) -> some View {
        let ring = item.isOn ? Palette.accent : Palette.line
        let fill = item.isOn ? Palette.accent.opacity(.subtle) : Color.clear
        let shape = RoundedRectangle(cornerRadius: corner.radius(16))

        return Button {
            withAnimation(.snappy) {
                item.toggle()
            }
        } label: {
            VStack(spacing: 8) {
                IconBadge(item.icon, size: 34)

                Text(item.name)
                    .textFont(.caption2)
                    .foregroundStyle(Palette.text)
                    .sharedTextScale()
            }
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(fill, in: shape)
            .overlay {
                shape
                    .stroke(ring, lineWidth: 1)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

private extension RecordsFilterSheet {
    static let sideWidth: CGFloat = 88

    static let columns = Array(
        repeating: GridItem(
            .flexible(),
            spacing: 12
        ),
        count: 4
    )

    var filter: EntryFilter {
        get {
            model.filter
        }
        nonmutating set {
            model.filter = newValue
        }
    }

    var list: EntryList? {
        model.list
    }

    var showTitle: String {
        let count = model.shownEntryCount
        return count > 0 ? "\(count) 件を表示" : "当てはまる記録はありません"
    }

    var tabOptions: [CapsulePicker<Tab>.Option] {
        let expense = tabTitle("支出", count: count(of: .expense))
        let income = tabTitle("収入", count: count(of: .income))
        let wallet = tabTitle("口座", count: filter.walletIds.count)
        let tag = tabTitle("タグ", count: filter.tagIds.count)

        return [
            .init(expense, value: .expense),
            .init(income, value: .income),
            .init(wallet, value: .wallet),
            .init(tag, value: .tag)
        ]
    }

    var isEmpty: Bool {
        switch tab {
        case .tag: tagGroups.isEmpty
        case .expense, .income, .wallet: items(in: tab).isEmpty
        }
    }

    var emptyText: String {
        switch tab {
        case .tag where !filter.categoryIds.isEmpty:
            "選んだカテゴリにはタグがありません"

        case .tag:
            "カテゴリの編集でタグを足すと、ここで選べます"

        case .expense, .income, .wallet:
            "選べるものがありません"
        }
    }

    var tagGroups: [TagGroup] {
        let tags = list?.filterTags ?? []

        return shownCategories.compactMap { category in
            let items = tags
                .filter { $0.categoryId == category.id }
                .map { TagLine.Item(id: $0.id, name: $0.name) }

            guard !items.isEmpty else {
                return nil
            }

            return TagGroup(
                category: category,
                icon: list?.icons[category.iconId],
                tags: items
            )
        }
    }

    var shownCategories: [EntryCategory] {
        let categories = list?.filterCategories ?? []

        guard !filter.categoryIds.isEmpty else {
            return categories
        }

        return categories.filter { filter.categoryIds.contains($0.id) }
    }

    var walletItems: [Item] {
        let wallets = list?.filterWallets ?? []

        return wallets.map { wallet in
            Item(
                id: wallet.id,
                name: wallet.name,
                icon: list?.icons[wallet.iconId],
                isOn: filter.walletIds.contains(wallet.id)
            ) {
                toggle(wallet.id, in: \.walletIds)
            }
        }
    }

    func tabTitle(
        _ title: String,
        count: Int
    ) -> String {
        count > 0 ? "\(title) \(count)" : title
    }

    func count(of kind: EntryCategory.Kind) -> Int {
        let categories = list?.filterCategories ?? []

        return categories
            .filter { $0.kind == kind && filter.categoryIds.contains($0.id) }
            .count
    }

    func items(in tab: Tab) -> [Item] {
        switch tab {
        case .expense: categoryItems(.expense)
        case .income: categoryItems(.income)
        case .wallet: walletItems
        case .tag: []
        }
    }

    func categoryItems(_ kind: EntryCategory.Kind) -> [Item] {
        let categories = list?.filterCategories ?? []

        return categories
            .filter { $0.kind == kind }
            .map { category in
                Item(
                    id: category.id,
                    name: category.name,
                    icon: list?.icons[category.iconId],
                    isOn: filter.categoryIds.contains(category.id)
                ) {
                    toggle(category.id, in: \.categoryIds)
                    keepShownTags()
                }
            }
    }

    func keepShownTags() {
        let shown = Set(tagGroups.flatMap { $0.tags.map(\.id) })
        filter.tagIds.formIntersection(shown)
    }

    func toggle<ID: Hashable>(
        _ id: ID,
        in keyPath: WritableKeyPath<EntryFilter, Set<ID>>
    ) {
        if filter[keyPath: keyPath].contains(id) {
            filter[keyPath: keyPath].remove(id)
        } else {
            filter[keyPath: keyPath].insert(id)
        }
    }
}
