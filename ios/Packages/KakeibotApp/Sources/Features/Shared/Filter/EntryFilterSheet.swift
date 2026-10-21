import Core
import DesignSystem
import Store
import SwiftUI

struct EntryFilterSheet: View {
    @Binding var filter: EntryFilter

    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeStyle.corner) private var corner

    let list: EntryList?

    var body: some View {
        VStack(spacing: 18) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    section("支出", items: categoryItems(.expense))

                    section("収入", items: categoryItems(.income))

                    section("口座", items: walletItems)
                }
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
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

private extension EntryFilterSheet {
    struct Item: Identifiable {
        let id: AnyHashable
        let name: String
        let icon: Icon?
        let isOn: Bool
        let toggle: () -> Void
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

    @ViewBuilder
    func section(
        _ title: String,
        items: [Item]
    ) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .textFont(.caption2)
                    .tracking(3)
                    .foregroundStyle(Palette.accent)
                    .padding(.leading, 4)

                LazyVGrid(columns: Self.columns, spacing: 10) {
                    ForEach(items) { item in
                        choice(item)
                    }
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

private extension EntryFilterSheet {
    static let sideWidth: CGFloat = 88

    static let columns = Array(
        repeating: GridItem(.flexible(), spacing: 10),
        count: 4
    )

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
                }
            }
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
