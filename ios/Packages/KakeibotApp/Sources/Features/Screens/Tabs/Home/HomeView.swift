import Core
import DesignSystem
import SwiftUI

public struct HomeView: View {
    @Bindable private var model: HomeModel

    @State private var openId: Entry.ID?
    @State private var orderButtonFrame: CGRect = .zero

    private let onOpenEntry: (Entry.ID) -> Void
    private let onShowRecords: () -> Void
    private let onOpenSettings: () -> Void
    private let onUseTemplate: (EntryTemplate) -> Void
    private let onShowAllTemplates: () -> Void
    private let onOpenOrderMenu: (CGRect) -> Void
    private let onAddTemplate: () -> Void
    private let onDeleteEntry: (Entry.ID) -> Void
    private let onOpenRecurrings: () -> Void

    public init(
        model: HomeModel,
        onOpenEntry: @escaping (Entry.ID) -> Void,
        onShowRecords: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void,
        onUseTemplate: @escaping (EntryTemplate) -> Void,
        onShowAllTemplates: @escaping () -> Void,
        onOpenOrderMenu: @escaping (CGRect) -> Void,
        onAddTemplate: @escaping () -> Void,
        onDeleteEntry: @escaping (Entry.ID) -> Void,
        onOpenRecurrings: @escaping () -> Void
    ) {
        self.model = model
        self.onOpenEntry = onOpenEntry
        self.onShowRecords = onShowRecords
        self.onOpenSettings = onOpenSettings
        self.onUseTemplate = onUseTemplate
        self.onShowAllTemplates = onShowAllTemplates
        self.onOpenOrderMenu = onOpenOrderMenu
        self.onAddTemplate = onAddTemplate
        self.onDeleteEntry = onDeleteEntry
        self.onOpenRecurrings = onOpenRecurrings
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                header
                dialCard
                templateCard
                recentCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .background {
            Rectangle()
                .fill(Palette.background)
                .ignoresSafeArea()
        }
    }
}

private extension HomeView {
    var header: some View {
        HStack {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(model.month.month)月")
                    .displayFont(.body)
                    .tracking(3)
                    .foregroundStyle(Palette.accent)

                Text(model.monthRangeText)
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
            }

            Spacer()
            HeaderButton(systemImage: "gearshape", action: onOpenSettings)
        }
    }

    var dialCard: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottom) {
                HalfDial(progress: model.budgetUsage?.progress, tint: dialTint)

                VStack(spacing: 2) {
                    Text(dialTitle)
                        .textFont(size: .caption)
                        .tracking(4)
                        .foregroundStyle(Palette.accent)

                    Text(dialAmount)
                        .displayFont(.display, weight: .bold)
                        .monospacedDigit()
                        .foregroundStyle(dialAmountColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .contentTransition(.numericText())
                }
            }
            .frame(maxWidth: 290)
            .animation(.snappy, value: model.budgetUsage)

            if let usage = model.budgetUsage {
                VStack(spacing: 4) {
                    if let warning = usage.warningText {
                        Text(warning)
                            .textFont(.caption, weight: .semibold)
                            .foregroundStyle(usage.tint)
                    }

                    HStack(spacing: 16) {
                        Text("予算 \(AmountText.text(usage.budget))")
                        Text("1 日あたり \(AmountText.text(usage.perDay))")
                    }
                    .textFont(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)
                }
            } else {
                Button(action: onOpenSettings) {
                    HStack(spacing: 4) {
                        Text("予算を決めると、あといくら使えるかが出ます")

                        Image(systemName: "chevron.right")
                            .sansFont(.micro, weight: .semibold)
                    }
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
                    .frame(minHeight: 32)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }

            if model.recurringExpense > 0 {
                Button(action: onOpenRecurrings) {
                    VStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Label(recurringText, systemImage: "repeat")

                            Image(systemName: "chevron.right")
                                .sansFont(.micro, weight: .semibold)
                        }
                        .textFont(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(Palette.subtext)

                        recurringProgress
                    }
                    .frame(minHeight: 28)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 0) {
                stat(
                    "今日",
                    amount: model.todayExpense,
                    color: Palette.accentStrong
                )

                divider

                stat(
                    middleTitle,
                    amount: middleAmount,
                    color: Palette.text
                )

                divider

                stat(
                    "今月の収入",
                    amount: model.monthIncome,
                    color: Palette.accent
                )
            }
            .padding(.top, 12)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Palette.accent.opacity(.soft))
                    .frame(height: 1)
            }
        }
        .padding(16)
        .padding(.top, 4)
        .card(cornerRadius: 24)
    }

    var templateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                HStack {
                    SectionTitle("テンプレート")
                    Spacer()

                    Button("すべて", action: onShowAllTemplates)
                        .textFont(.caption)
                        .foregroundStyle(Palette.accent)
                        .frame(minHeight: 44)
                }

                CapsulePicker(
                    selection: $model.templateType,
                    options: Self.typeOptions
                )
            }
            .padding(.top, 8)

            HStack(spacing: 8) {
                Text(templateHint)
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)

                Spacer()

                if model.templates.count > 1 {
                    orderButton
                }

                Button(action: onAddTemplate) {
                    Image(systemName: "plus")
                        .sansFont(.small, weight: .light)
                        .foregroundStyle(Palette.accent)
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
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .card()
    }

    var orderButton: some View {
        Button {
            onOpenOrderMenu(orderButtonFrame)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.arrow.down")
                    .sansFont(.caption, weight: .light)

                Text(model.templateOrder.title)
                    .textFont(.caption2)
            }
            .foregroundStyle(Palette.accent)
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
            repeating: GridItem(.fixed(Self.tileHeight), spacing: 12),
            count: shelfRowCount
        )

        return ScrollView(.horizontal) {
            LazyHGrid(rows: rows, spacing: 12) {
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
        .scrollClipDisabled()
        .mask {
            Rectangle()
                .padding(.vertical, -Self.shadowRoom)
        }
        .padding(.horizontal, -16)
        .padding(.vertical, -8)
    }

    var recentCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                SectionTitle("最近の記録")
                Spacer()

                Button("すべて", action: onShowRecords)
                    .textFont(.caption)
                    .foregroundStyle(Palette.accent)
                    .frame(minHeight: 44)
            }

            if model.recentRows.isEmpty {
                Text("まだ記録がありません。右下の ＋ から記録できます")
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
                    .padding(.vertical, 16)
            } else {
                ForEach(model.recentRows) { row in
                    SwipeRow(id: row.id, openId: $openId) {
                        onOpenEntry(row.id)
                    } onAction: {
                        onDeleteEntry(row.id)
                    } content: {
                        EntryRow(
                            icon: row.icon,
                            title: row.title,
                            tag: row.tag,
                            detail: row.detail,
                            memo: row.memo,
                            amount: row.amount,
                            type: row.type,
                            isRecurring: row.isRecurring
                        )
                    }
                    .overlay(alignment: .top) {
                        Hairline(thickness: 1)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .card()
    }

    var divider: some View {
        Rectangle()
            .fill(Palette.accent.opacity(.soft))
            .frame(width: 1, height: 32)
    }

    var recurringProgress: some View {
        Capsule()
            .fill(Palette.faint)
            .frame(width: 120, height: 3)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(Palette.accent)
                    .frame(width: 120 * model.paidRecurringRatio)
            }
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

    func stat(
        _ title: String,
        amount: Int,
        color: Color
    ) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .textFont(.caption2)
                .foregroundStyle(Palette.subtext)

            Text(AmountText.text(amount))
                .displayFont(.body)
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
    static let shadowRoom: CGFloat = 32
    static let toolStroke = Palette.accent.opacity(.muted)

    var dialTitle: String {
        model.budgetUsage == nil ? "今月の支出" : "今月あといくら"
    }

    var dialAmount: String {
        guard let usage = model.budgetUsage else {
            return AmountText.text(model.monthExpense)
        }

        return AmountText.text(usage.remaining)
    }

    var dialAmountColor: Color {
        model.budgetUsage?.amountTint ?? Palette.accentStrong
    }

    var middleTitle: String {
        model.budgetUsage == nil ? "昨日" : "今月の支出"
    }

    var middleAmount: Int {
        model.budgetUsage == nil ? model.yesterdayExpense : model.monthExpense
    }

    var recurringText: String {
        let total = "今月の固定費 \(AmountText.text(model.recurringExpense))"
        let upcoming = model.upcomingRecurringExpense

        guard upcoming > 0 else {
            return total
        }

        return "\(total)・これから \(AmountText.text(upcoming))"
    }

    var dialTint: Color {
        model.budgetUsage?.tint ?? Palette.accent
    }

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
