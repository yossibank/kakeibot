import Core
import DesignSystem
import SwiftUI

public struct HomeView: View {
    @Bindable private var model: HomeModel

    @State private var openId: Entry.ID?
    @State private var orderButtonFrame: CGRect = .zero

    private let setup: SetupModel
    private let appIcon: AppIconListModel
    private let isSheetOpen: Bool
    private let onOpenEntry: (Entry.ID) -> Void
    private let onShowRecords: () -> Void
    private let onRetry: () -> Void
    private let onOpenSettings: () -> Void
    private let onUseTemplate: (EntryTemplate) -> Void
    private let onShowAllTemplates: () -> Void
    private let onOpenOrderMenu: (CGRect) -> Void
    private let onAddTemplate: () -> Void
    private let onDeleteEntry: (Entry.ID) -> Void
    private let onOpenRecurrings: () -> Void
    private let onOpenRecurring: (Recurring.ID) -> Void
    private let onOpenSetup: (SetupItem) -> Void

    public init(
        model: HomeModel,
        setup: SetupModel,
        appIcon: AppIconListModel,
        isSheetOpen: Bool,
        onOpenEntry: @escaping (Entry.ID) -> Void,
        onShowRecords: @escaping () -> Void,
        onRetry: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void,
        onUseTemplate: @escaping (EntryTemplate) -> Void,
        onShowAllTemplates: @escaping () -> Void,
        onOpenOrderMenu: @escaping (CGRect) -> Void,
        onAddTemplate: @escaping () -> Void,
        onDeleteEntry: @escaping (Entry.ID) -> Void,
        onOpenRecurrings: @escaping () -> Void,
        onOpenRecurring: @escaping (Recurring.ID) -> Void,
        onOpenSetup: @escaping (SetupItem) -> Void
    ) {
        self.model = model
        self.setup = setup
        self.appIcon = appIcon
        self.isSheetOpen = isSheetOpen
        self.onOpenEntry = onOpenEntry
        self.onShowRecords = onShowRecords
        self.onRetry = onRetry
        self.onOpenSettings = onOpenSettings
        self.onUseTemplate = onUseTemplate
        self.onShowAllTemplates = onShowAllTemplates
        self.onOpenOrderMenu = onOpenOrderMenu
        self.onAddTemplate = onAddTemplate
        self.onDeleteEntry = onDeleteEntry
        self.onOpenRecurrings = onOpenRecurrings
        self.onOpenRecurring = onOpenRecurring
        self.onOpenSetup = onOpenSetup
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                header

                if setup.showsCard {
                    HomeSetupCard(model: setup, onOpen: onOpenSetup)
                        .transition(Self.cardTransition)
                }

                ForEach(model.homeLayout.visible) { section in
                    sectionView(section)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .animation(.snappy, value: setup.showsCard)
            .animation(.snappy, value: model.homeLayout)
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

            HeaderButton(
                systemImage: "gearshape",
                showsDot: !setup.isSettingsOpened,
                action: onOpenSettings
            )
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

            VStack(spacing: 4) {
                if let usage = model.budgetUsage {
                    VStack(spacing: 4) {
                        if let warning = usage.warningText {
                            Text(warning)
                                .textFont(.caption, weight: .semibold)
                                .foregroundStyle(usage.tint)
                        }

                        Button {
                            onOpenSetup(.budget)
                        } label: {
                            HStack(spacing: 4) {
                                Text("予算 \(AmountText.text(usage.budget))")

                                Image(systemName: "chevron.right")
                                    .sansFont(.micro, weight: .semibold)
                            }
                            .textFont(.caption)
                            .monospacedDigit()
                            .foregroundStyle(Palette.subtext)
                            .padding(.vertical, 4)
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Button {
                        onOpenSetup(.budget)
                    } label: {
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
                        .padding(.vertical, 4)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
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

            if model.isListFailed {
                LoadFailedNotice(onRetry: onRetry)
            } else if model.recentRows.isEmpty {
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
                            route: row.route,
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

    var billCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                SectionTitle("これからの引き落とし")

                Spacer()

                if !model.upcomingBills.isEmpty {
                    Text("合計 \(AmountText.text(model.upcomingBillTotal))")
                        .textFont(.caption)
                        .monospacedDigit()
                        .foregroundStyle(Palette.subtext)
                }
            }
            .frame(minHeight: 44)

            if model.upcomingBills.isEmpty {
                Text("これからの引き落としはありません")
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
                    .padding(.vertical, 16)
            } else {
                ForEach(model.upcomingBills, id: \.recurring.id) { bill in
                    Button {
                        onOpenRecurring(bill.recurring.id)
                    } label: {
                        billRow(bill)
                    }
                    .buttonStyle(.plain)
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

    var stampCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("今月のスタンプ")
                .frame(minHeight: 44)

            if model.stampTallies.isEmpty {
                Text("今月はまだスタンプを押していません")
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
                    .padding(.bottom, 8)
            } else {
                LazyVGrid(columns: Self.stampColumns, alignment: .leading) {
                    ForEach(model.stampTallies) { tally in
                        HStack(spacing: 8) {
                            IconSeal(tally.icon, size: 28)

                            Text("×\(tally.count)")
                                .displayFont(.body)
                                .monospacedDigit()
                                .foregroundStyle(Palette.accentStrong)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
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

    func billRow(_ bill: CardBill) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(bill.date.month)/\(bill.date.day)")
                    .displayFont(.body)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accent)

                Text(daysText(until: bill.date))
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)
            }
            .frame(width: Self.billDateWidth, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(model.title(of: bill.recurring))
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)

                if bill.shortage > 0 {
                    Text("残高が \(AmountText.text(bill.shortage)) 足りません")
                        .textFont(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(Palette.rose)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            Text(AmountText.text(bill.amount))
                .displayFont(.headline)
                .monospacedDigit()
                .foregroundStyle(Palette.accentStrong)
                .lineLimit(1)
        }
        .padding(.vertical, 12)
        .contentShape(.rect)
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

    @ViewBuilder
    func sectionView(_ section: HomeSection) -> some View {
        switch section {
        case .customize:
            HomeCustomizeCard(
                model: setup,
                appIcon: appIcon,
                isSheetOpen: isSheetOpen,
                onOpen: onOpenSetup,
                onClose: {
                    Task {
                        await model.hide(.customize)
                    }
                }
            )
            .transition(Self.cardTransition)
        case .budget:
            dialCard
        case .templates:
            templateCard
        case .recent:
            recentCard
        case .bills:
            billCard
        case .stamps:
            stampCard
        }
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
    static let billDateWidth: CGFloat = 56

    static let stampColumns = [
        GridItem(.adaptive(minimum: 72), spacing: 12, alignment: .leading)
    ]

    static var cardTransition: AnyTransition {
        .offset(y: 16).combined(with: .opacity)
    }

    var dialTitle: String {
        model.budgetUsage?.remainingTitle ?? "今月の支出"
    }

    var dialAmount: String {
        guard let usage = model.budgetUsage else {
            return AmountText.text(model.monthExpense)
        }

        return usage.remainingAmountText
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

    func daysText(until date: LocalDate) -> String {
        let days = model.today.days(until: date)
        return days == 1 ? "明日" : "あと \(days) 日"
    }
}

private extension View {
    func shelfWidth() -> some View {
        containerRelativeFrame(.horizontal) { width, _ in
            width * 0.62
        }
    }
}
