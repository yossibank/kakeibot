import Core
import DesignSystem
import FeatureModels
import SwiftUI

public struct HomeView: View {
    @Bindable var model: HomeModel

    @State var layout = Layout()

    let onUseTemplate: (EntryTemplate) -> Void
    let onShowAllTemplates: () -> Void
    let onOpenOrderMenu: (CGRect) -> Void
    let onAddTemplate: () -> Void
    let onOpenRecurrings: () -> Void
    let onOpenRecurring: (Recurring.ID) -> Void
    let onOpenSetup: (SetupItem) -> Void
    let onOpenDay: (LocalDate) -> Void

    private let setup: SetupModel
    private let appIcon: AppIconListModel
    private let isSheetOpen: Bool
    private let onOpenEntry: (Entry.ID) -> Void
    private let onShowRecords: () -> Void
    private let onAddEntry: (LocalDate) -> Void
    private let onRetry: () -> Void
    private let onOpenSettings: () -> Void
    private let onOpenNews: () -> Void
    private let onDeleteEntry: (Entry.ID) -> Void

    public init(
        model: HomeModel,
        setup: SetupModel,
        appIcon: AppIconListModel,
        isSheetOpen: Bool,
        onOpenEntry: @escaping (Entry.ID) -> Void,
        onShowRecords: @escaping () -> Void,
        onAddEntry: @escaping (LocalDate) -> Void,
        onRetry: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void,
        onOpenNews: @escaping () -> Void,
        onUseTemplate: @escaping (EntryTemplate) -> Void,
        onShowAllTemplates: @escaping () -> Void,
        onOpenOrderMenu: @escaping (CGRect) -> Void,
        onAddTemplate: @escaping () -> Void,
        onDeleteEntry: @escaping (Entry.ID) -> Void,
        onOpenRecurrings: @escaping () -> Void,
        onOpenRecurring: @escaping (Recurring.ID) -> Void,
        onOpenSetup: @escaping (SetupItem) -> Void,
        onOpenDay: @escaping (LocalDate) -> Void
    ) {
        self.model = model
        self.setup = setup
        self.appIcon = appIcon
        self.isSheetOpen = isSheetOpen
        self.onOpenEntry = onOpenEntry
        self.onShowRecords = onShowRecords
        self.onAddEntry = onAddEntry
        self.onRetry = onRetry
        self.onOpenSettings = onOpenSettings
        self.onOpenNews = onOpenNews
        self.onUseTemplate = onUseTemplate
        self.onShowAllTemplates = onShowAllTemplates
        self.onOpenOrderMenu = onOpenOrderMenu
        self.onAddTemplate = onAddTemplate
        self.onDeleteEntry = onDeleteEntry
        self.onOpenRecurrings = onOpenRecurrings
        self.onOpenRecurring = onOpenRecurring
        self.onOpenSetup = onOpenSetup
        self.onOpenDay = onOpenDay
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                header

                TwoColumnStack(
                    spacing: 12,
                    minWidth: Self.twoColumnWidth,
                    isLazy: false
                ) {
                    if setup.output.showsCard {
                        setupCard
                    }

                    ForEach(model.output.homeLayout.visible) { section in
                        sectionView(section)
                            .layoutColumn(Self.column(of: section))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .animation(.snappy, value: setup.output.showsCard)
            .animation(.snappy, value: model.output.homeLayout)
        }
        .errorBanner(model.state.notices.error)
        .sheet(
            item: Bindable(model.state).presented.stamp.item,
            onDismiss: openPendingDay
        ) { tally in
            StampDaysSheet(
                tally: tally,
                periodTitle: periodTitle,
                days: model.output.stampDays(of: tally),
                entryDay: model.output.day(on:)
            ) { date in
                model.state.pickStampDay(date)
            }
        }
        .backdrop()
    }
}

extension HomeView {
    struct Layout {
        var shelfWidth: CGFloat = 0
    }
}

private extension HomeView {
    var header: some View {
        TabHeader("\(model.output.month.month)月", subtitle: model.output.monthRangeText) {
            HStack(spacing: 8) {
                HeaderButton(systemImage: "bell", action: onOpenNews)
                    .overlay(alignment: .topTrailing) {
                        if setup.output.hasUnreadNews {
                            headerDot(Palette.rose)
                        }
                    }
                    .animation(.snappy, value: setup.output.hasUnreadNews)

                HeaderButton(systemImage: "gearshape", action: onOpenSettings)
                    .overlay(alignment: .topTrailing) {
                        if model.input.syncStatus.hasTrouble {
                            headerDot(Palette.amber)
                        }
                    }
                    .animation(.snappy, value: model.input.syncStatus.hasTrouble)
            }
        }
    }

    var setupCard: some View {
        HomeSetupCard(model: setup, onOpen: onOpenSetup)
            .transition(Self.cardTransition)
    }

    var recentCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            CardHeader("最近の記録") {
                Button("すべて", action: onShowRecords)
                    .textFont(.caption)
                    .foregroundStyle(Palette.accent)
                    .frame(minHeight: 44)
            }

            if model.input.list.isFailed {
                LoadFailedPlaceholder(onRetry: onRetry)
            } else if model.output.showsNoRecords {
                EmptyPlaceholder(
                    systemImage: "square.and.pencil",
                    text: "まだ記録がありません",
                    onRecord: {
                        onAddEntry(model.input.today)
                    }
                )
            } else {
                ForEach(model.output.recentRows) { row in
                    SwipeRow(id: row.id, openId: Bindable(model.state).presented.row.item) {
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
                    .topHairline()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .card()
        .sharesTextScale(id: model.output.recentRows)
    }

    var stampCard: some View {
        StampTallyCard(
            tallies: model.output.stampTallies,
            emptyText: "今月はまだスタンプを押していません",
            onOpen: { tally in
                model.state.presented.stamp.show(tally)
            }
        )
    }

    func headerDot(_ color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 9, height: 9)
            .offset(x: -3, y: 5)
            .transition(.scale.combined(with: .opacity))
    }

    @ViewBuilder
    func sectionView(_ section: HomeSection) -> some View {
        switch section {
        case .customize:
            HomeCustomizeCard(
                glowing: Bindable(model.state).presented.glow.item,
                model: setup,
                appIcon: appIcon,
                isSheetOpen: isSheetOpen,
                onOpen: onOpenSetup,
                onChange: model.state.customize,
                onSheetClose: model.state.finishCustomizing,
                onClose: {
                    model.perform {
                        await $0.hide(.customize)
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
    static let twoColumnWidth: CGFloat = 760

    static var cardTransition: AnyTransition {
        .offset(y: 16).combined(with: .opacity)
    }

    var periodTitle: String {
        model.output.month.title
    }

    static func column(of section: HomeSection) -> TwoColumnLayout.Column {
        switch section {
        case .customize, .budget, .templates: .leading
        case .recent, .bills, .stamps: .trailing
        }
    }

    func openPendingDay() {
        if let date = model.state.takePendingDay() {
            onOpenDay(date)
        }
    }
}
