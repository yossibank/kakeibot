import Core
import DesignSystem
import SwiftUI

struct HomeView: View {
    @Bindable var model: HomeModel

    @State private var openId: Entry.ID?
    @State private var orderButtonFrame: CGRect = .zero

    let onOpenEntry: (Entry.ID) -> Void
    let onShowRecords: () -> Void
    let onOpenSettings: () -> Void
    let onUseTemplate: (EntryTemplate) -> Void
    let onShowAllTemplates: () -> Void
    let onOpenOrderMenu: (CGRect) -> Void
    let onAddTemplate: () -> Void
    let onDeleteEntry: (Entry.ID) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                header
                dialCard
                templateCard
                recentCard

                if let errorMessage = model.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Palette.rose)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background {
            Rectangle()
                .fill(Palette.night)
                .ignoresSafeArea()
        }
    }
}

private extension HomeView {
    var header: some View {
        HStack {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(model.month.month)月")
                    .font(.system(size: 15, design: .serif))
                    .tracking(3)
                    .foregroundStyle(Palette.gold)

                Text(model.monthRangeText)
                    .font(.caption)
                    .foregroundStyle(Palette.mist)
            }

            Spacer()

            Button(action: onOpenSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 17, weight: .light))
                    .foregroundStyle(Palette.gold)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Circle()
                            .stroke(Palette.gold.opacity(0.28), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
        }
    }

    var dialCard: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .bottom) {
                HalfDial()

                VStack(spacing: 2) {
                    Text("今月の支出")
                        .font(.system(size: 11))
                        .tracking(4)
                        .foregroundStyle(Palette.gold)

                    Text(AmountText.text(model.monthExpense))
                        .font(.system(size: 40, weight: .bold, design: .serif))
                        .monospacedDigit()
                        .foregroundStyle(Palette.champagne)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
            .frame(maxWidth: 290)

            HStack(spacing: 0) {
                stat("今日", amount: model.todayExpense, color: Palette.champagne)
                divider
                stat("昨日", amount: model.yesterdayExpense, color: Palette.ink)
                divider
                stat("今月の収入", amount: model.monthIncome, color: Palette.gold)
            }
            .padding(.top, 12)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Palette.gold.opacity(0.18))
                    .frame(height: 1)
            }
        }
        .padding(16)
        .padding(.top, 4)
        .card(cornerRadius: 24)
    }

    var templateCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                HStack {
                    SectionTitle("テンプレート")

                    Spacer()

                    Button("すべて", action: onShowAllTemplates)
                        .font(.caption)
                        .foregroundStyle(Palette.gold)
                        .frame(minHeight: 44)
                }

                CapsulePicker(
                    selection: $model.templateType,
                    options: Self.typeOptions
                )
            }
            .padding(.top, 8)

            HStack(spacing: 6) {
                Text(templateHint)
                    .font(.caption2)
                    .foregroundStyle(Palette.mist)

                Spacer()

                if model.templates.count > 1 {
                    orderButton
                }

                Button(action: onAddTemplate) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(Palette.gold)
                        .frame(width: 32, height: 32)
                        .overlay {
                            Circle()
                                .stroke(Self.toolStroke, lineWidth: 1)
                        }
                        .frame(width: 40, height: 40)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }

            if !model.templates.isEmpty {
                templateShelf
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
        .card()
    }

    var orderButton: some View {
        Button {
            onOpenOrderMenu(orderButtonFrame)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 11, weight: .light))

                Text(model.templateOrder.title)
                    .font(.caption2)
            }
            .foregroundStyle(Palette.gold)
            .padding(.horizontal, 12)
            .frame(height: 32)
            .overlay {
                Capsule()
                    .stroke(Self.toolStroke, lineWidth: 1)
            }
            .frame(height: 40)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { frame in
            orderButtonFrame = frame
        }
    }

    var templateShelf: some View {
        let rows = Array(
            repeating: GridItem(.fixed(Self.tileHeight), spacing: 10),
            count: shelfRowCount
        )

        return ScrollView(.horizontal) {
            LazyHGrid(rows: rows, spacing: 10) {
                ForEach(model.templates) { template in
                    templateButton(template)
                        .shelfWidth()
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned)
        .contentMargins(.horizontal, 14, for: .scrollContent)
        .contentMargins(.vertical, 6, for: .scrollContent)
        .padding(.horizontal, -14)
        .padding(.vertical, -6)
    }

    var recentCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                SectionTitle("最近の記録")

                Spacer()

                Button("すべて", action: onShowRecords)
                    .font(.caption)
                    .foregroundStyle(Palette.gold)
                    .frame(minHeight: 44)
            }

            if model.recentRows.isEmpty {
                Text("まだ記録がありません。右下の ＋ から記録できます")
                    .font(.footnote)
                    .foregroundStyle(Palette.mist)
                    .padding(.vertical, 16)
            } else {
                ForEach(model.recentRows) { row in
                    SwipeRow(id: row.id, openId: $openId) {
                        onOpenEntry(row.id)
                    } onDelete: {
                        onDeleteEntry(row.id)
                    } content: {
                        EntryRow(
                            icon: row.icon,
                            title: row.title,
                            tag: row.tag,
                            detail: row.detail,
                            amount: row.amount,
                            type: row.type
                        )
                    }
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(Palette.gold.opacity(0.1))
                            .frame(height: 1)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
        .card()
    }

    func templateButton(_ template: EntryTemplate) -> some View {
        Button {
            onUseTemplate(template)
        } label: {
            TemplateCard(
                icon: model.icon(for: template),
                name: template.name,
                detail: model.detail(for: template),
                amount: template.amount
            )
        }
        .buttonStyle(.plain)
    }

    var divider: some View {
        Rectangle()
            .fill(Palette.gold.opacity(0.18))
            .frame(width: 1, height: 32)
    }

    func stat(
        _ title: String,
        amount: Int,
        color: Color
    ) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(Palette.mist)

            Text(AmountText.text(amount))
                .font(.system(size: 16, design: .serif))
                .monospacedDigit()
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }
}

private extension HomeView {
    static let typeOptions: [CapsulePicker<Entry.Kind>.Option] = [
        .init("支出", value: .expense),
        .init("収入", value: .income)
    ]

    static let tileHeight = TemplateCardSize.regular.height
    static let toolStroke = Palette.gold.opacity(0.35)

    var shelfRowCount: Int {
        model.templates.count > 2 ? 2 : 1
    }

    var templateHint: String {
        model.templates.isEmpty ? "よく使う入力を 1 回で" : "押すとすぐ記録"
    }
}

private extension View {
    func shelfWidth() -> some View {
        containerRelativeFrame(.horizontal) { width, _ in
            width * 0.62
        }
    }
}
