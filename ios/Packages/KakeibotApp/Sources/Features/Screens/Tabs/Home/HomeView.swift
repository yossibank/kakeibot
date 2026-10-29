import Core
import DesignSystem
import SwiftUI

public struct HomeView: View {
    @Bindable var model: HomeModel

    @State var orderButtonFrame: CGRect = .zero

    @State private var openId: Entry.ID?

    let onUseTemplate: (EntryTemplate) -> Void
    let onShowAllTemplates: () -> Void
    let onOpenOrderMenu: (CGRect) -> Void
    let onAddTemplate: () -> Void
    let onOpenRecurrings: () -> Void
    let onOpenRecurring: (Recurring.ID) -> Void
    let onOpenSetup: (SetupItem) -> Void

    private let setup: SetupModel
    private let appIcon: AppIconListModel
    private let isSheetOpen: Bool
    private let onOpenEntry: (Entry.ID) -> Void
    private let onShowRecords: () -> Void
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

    var setupCard: some View {
        HomeSetupCard(model: setup, onOpen: onOpenSetup)
            .transition(Self.cardTransition)
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
            } else if model.showsNoRecords {
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
        .sharesTextScale(id: model.recentRows)
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
    static let stampColumns = [
        GridItem(.adaptive(minimum: 72), spacing: 12, alignment: .leading)
    ]

    static var cardTransition: AnyTransition {
        .offset(y: 16).combined(with: .opacity)
    }
}
