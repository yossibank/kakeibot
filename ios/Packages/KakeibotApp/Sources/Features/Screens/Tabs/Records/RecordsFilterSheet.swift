import Core
import DesignSystem
import Store
import SwiftUI

struct RecordsFilterSheet: View {
    @Binding var filter: EntryFilter

    @State private var tab: Tab = .expense

    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeStyle.corner) private var corner

    let list: EntryList?

    var body: some View {
        VStack(spacing: 18) {
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
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(tagGroups) { group in
                                tagGroup(group)
                            }
                        }
                        .padding(.vertical, 4)
                    } else {
                        LazyVGrid(columns: Self.columns, spacing: 10) {
                            ForEach(items(in: tab)) { item in
                                choice(item)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            Rectangle()
                .fill(Palette.background)
                .ignoresSafeArea()
        }
        .sensoryFeedback(.selection, trigger: filter)
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

            Text("絞り込む")
                .displayFont(.body)
                .tracking(2)
                .foregroundStyle(Palette.accent)

            Spacer()

            ZStack {
                if !filter.isEmpty {
                    Button {
                        withAnimation(.snappy) {
                            filter = EntryFilter()
                        }
                    } label: {
                        Text("すべて外す")
                            .textFont(.caption)
                            .foregroundStyle(Palette.rose)
                            .frame(minHeight: 44)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }
            }
            .frame(width: Self.sideWidth, alignment: .trailing)
        }
    }

    func tagGroup(_ group: TagGroup) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                IconBadge(group.icon, size: 22)

                Text(group.category.name)
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
            }
            .padding(.leading, 6)

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
        let shape = RoundedRectangle(cornerRadius: corner.radius(14))

        return Button {
            withAnimation(.snappy) {
                item.toggle()
            }
        } label: {
            VStack(spacing: 6) {
                IconBadge(item.icon, size: 34)

                Text(item.name)
                    .textFont(.caption2)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
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
        repeating: GridItem(.flexible(), spacing: 10),
        count: 4
    )

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
