import Core
import DesignSystem
import Store
import SwiftUI

public struct HomeView: View {
    @Bindable var model: HomeModel

    @State var orderButtonFrame: CGRect = .zero

    @State private var openId: Entry.ID?
    @State private var openStamp: StampCalendar.Tally?
    @State private var pendingDay: LocalDate?

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

                if setup.showsCard {
                    setupCard
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
        .sheet(item: $openStamp, onDismiss: openPendingDay) { tally in
            StampDaysSheet(
                tally: tally,
                periodTitle: periodTitle,
                days: model.stampDays(of: tally),
                entryDay: model.day(on:)
            ) { date in
                pendingDay = date
                openStamp = nil
            }
        }
        .background {
            Backdrop()
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

            if model.isListFailed {
                LoadFailedNotice(onRetry: onRetry)
            } else if model.showsNoRecords {
                EmptyNote(text: "まだ記録がありません") {
                    onAddEntry(model.today)
                }
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
        .sharesTextScale(id: model.recentRows)
    }

    var stampCard: some View {
        StampTallyCard(
            tallies: model.stampTallies,
            emptyText: "今月はまだスタンプを押していません",
            onOpen: { tally in
                openStamp = tally
            }
        )
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
    static var cardTransition: AnyTransition {
        .offset(y: 16).combined(with: .opacity)
    }

    var periodTitle: String {
        "\(String(model.month.year))年 \(model.month.month)月"
    }

    func openPendingDay() {
        guard let pendingDay else {
            return
        }

        self.pendingDay = nil

        onOpenDay(pendingDay)
    }
}
