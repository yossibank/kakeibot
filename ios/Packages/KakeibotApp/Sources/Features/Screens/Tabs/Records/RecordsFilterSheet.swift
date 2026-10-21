import Core
import DesignSystem
import SwiftUI

struct RecordsFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeStyle.corner) private var corner

    let model: RecordsModel

    var body: some View {
        VStack(spacing: 18) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    section("支出", kind: .expense)

                    section("収入", kind: .income)
                }
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)

            if !model.filter.isEmpty {
                Button {
                    withAnimation(.snappy) {
                        model.clearFilter()
                    }
                } label: {
                    Label("すべて外す", systemImage: "xmark.circle")
                        .textFont(.subheadline)
                        .foregroundStyle(Palette.rose)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
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
        .sensoryFeedback(.selection, trigger: model.filter)
        .presentationDetents([.medium, .large])
    }
}

private extension RecordsFilterSheet {
    var header: some View {
        HStack {
            RingButton(systemImage: "xmark") {
                dismiss()
            }

            Spacer()

            Text("カテゴリで絞り込む")
                .displayFont(.body)
                .tracking(2)
                .foregroundStyle(Palette.accent)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
    }

    @ViewBuilder
    func section(
        _ title: String,
        kind: EntryCategory.Kind
    ) -> some View {
        let categories = model.filterCategories.filter { $0.kind == kind }

        if !categories.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .textFont(.caption2)
                    .tracking(3)
                    .foregroundStyle(Palette.accent)
                    .padding(.leading, 4)

                LazyVGrid(columns: Self.columns, spacing: 10) {
                    ForEach(categories) { category in
                        choice(category)
                    }
                }
            }
        }
    }

    func choice(_ category: EntryCategory) -> some View {
        let isOn = model.filter.categoryIds.contains(category.id)
        let ring = isOn ? Palette.accent : Palette.line
        let fill = isOn ? Palette.accent.opacity(.subtle) : Color.clear
        let shape = RoundedRectangle(cornerRadius: corner.radius(14))

        return Button {
            withAnimation(.snappy) {
                model.toggleFilter(category.id)
            }
        } label: {
            VStack(spacing: 6) {
                IconBadge(model.icon(of: category), size: 34)

                Text(category.name)
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
    static let columns = Array(
        repeating: GridItem(.flexible(), spacing: 10),
        count: 4
    )
}
