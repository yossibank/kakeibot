import Core
import DesignSystem
import Store
import SwiftUI

public struct SettingsSheet: View {
    @State private var monthStartDay: MonthStartDay = .first
    @State private var launchScreen: LaunchScreen = .home
    @State private var startsWithAmount = false
    @State private var weekStart: Weekday = .sunday
    @State private var reminderTime: ReminderTime?
    @State private var theme: ThemeChoice = .system
    @State private var customThemes: [Theme] = []

    #if DEBUG
    @State private var isConfirmingSample = false
    @State private var isInsertingSample = false
    @State private var sampleMessage: String?
    #endif

    @Environment(\.dismiss) private var dismiss
    @Environment(\.notificationPermission) private var permission
    @Environment(\.themeStyle) private var themeStyle

    private let database: AppDatabase
    private let today: LocalDate
    private let appIcon: AppIconListModel

    public init(
        database: AppDatabase,
        today: LocalDate,
        appIcon: AppIconListModel
    ) {
        self.database = database
        self.today = today
        self.appIcon = appIcon
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            sectionTitle("入力")

                            VStack(spacing: 0) {
                                NavigationLink {
                                    WalletListView(database: database)
                                } label: {
                                    row("口座", systemImage: "building.columns")
                                }

                                Hairline()

                                NavigationLink {
                                    CategoryListView(database: database)
                                } label: {
                                    row("カテゴリ", systemImage: "tag")
                                }

                                Hairline()

                                NavigationLink {
                                    TemplateListView(database: database)
                                } label: {
                                    row(
                                        "テンプレート",
                                        systemImage: "rectangle.stack"
                                    )
                                }

                                Hairline()

                                NavigationLink {
                                    RecurringListView(
                                        model: RecurringListModel(
                                            database: database,
                                            today: today
                                        )
                                    )
                                } label: {
                                    row("固定費", systemImage: "repeat")
                                }

                                Hairline()

                                NavigationLink {
                                    StampListView(database: database)
                                } label: {
                                    row("スタンプ", systemImage: "seal")
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 16)
                            .card()
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            sectionTitle("期間と予算")

                            VStack(spacing: 0) {
                                NavigationLink {
                                    MonthStartDayView(
                                        model: MonthStartDayModel(
                                            database: database,
                                            today: today
                                        )
                                    )
                                } label: {
                                    row(
                                        "月の始まり",
                                        systemImage: "calendar",
                                        value: PeriodText
                                            .startDay(monthStartDay)
                                    )
                                }

                                Hairline()

                                NavigationLink {
                                    BudgetListView(
                                        model: BudgetListModel(
                                            database: database,
                                            today: today
                                        )
                                    )
                                } label: {
                                    row("予算", systemImage: "chart.bar")
                                }

                                Hairline()

                                NavigationLink {
                                    RewardRuleListView(database: database)
                                } label: {
                                    row("ごほうび", systemImage: "gift")
                                }

                                Hairline()

                                pickerRow(
                                    "週の始まり",
                                    systemImage: "calendar.day.timeline.left"
                                ) {
                                    CapsulePicker(
                                        selection: weekStartBinding,
                                        options: Weekday.weekStartOptions
                                    )
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 16)
                            .card()
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            sectionTitle("見た目")

                            VStack(spacing: 0) {
                                NavigationLink {
                                    ThemeListView(
                                        database: database,
                                        appIcon: appIcon
                                    )
                                } label: {
                                    row(
                                        "テーマ",
                                        systemImage: "paintpalette",
                                        value: theme.title(in: customThemes)
                                    )
                                }

                                Hairline()

                                NavigationLink {
                                    AppIconListView(model: appIcon)
                                } label: {
                                    row(
                                        "アプリアイコン",
                                        systemImage: "app.badge",
                                        value: appIcon.current.title
                                    )
                                }

                                Hairline()

                                NavigationLink {
                                    ThemeStyleView(
                                        model: ThemeStyleModel(
                                            database: database
                                        )
                                    )
                                } label: {
                                    row(
                                        "文字と角の丸み",
                                        systemImage: "textformat",
                                        value: themeStyle.title,
                                        shortValue: themeStyle.shortTitle
                                    )
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 16)
                            .card()
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            sectionTitle("使い方")

                            VStack(spacing: 0) {
                                NavigationLink {
                                    LaunchScreenView(
                                        model: LaunchScreenModel(
                                            database: database
                                        )
                                    )
                                } label: {
                                    row(
                                        "起動時に開く画面",
                                        systemImage: "iphone",
                                        value: launchScreen.title
                                    )
                                }

                                Hairline()

                                pickerRow(
                                    "金額から入力",
                                    systemImage: "yensign"
                                ) {
                                    CapsulePicker(
                                        selection: startsWithAmountBinding,
                                        options: Self.startOptions
                                    )
                                }

                                Hairline()

                                NavigationLink {
                                    ReminderView(
                                        model: ReminderModel(
                                            database: database,
                                            today: today,
                                            time: reminderTime,
                                            permission: permission
                                        )
                                    )
                                } label: {
                                    row(
                                        "記録忘れの通知",
                                        systemImage: "bell",
                                        value: reminderText
                                    )
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 16)
                            .card()
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            sectionTitle("データとアプリ")

                            VStack(spacing: 0) {
                                NavigationLink {
                                    BackupView(
                                        model: BackupModel(database: database)
                                    )
                                } label: {
                                    row(
                                        "バックアップ",
                                        systemImage: "externaldrive"
                                    )
                                }

                                Hairline()
                                versionRow
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 16)
                            .card()
                        }

                        #if DEBUG
                        sampleSection
                        #endif
                    }
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background {
                Rectangle()
                    .fill(Palette.background)
                    .ignoresSafeArea()
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task {
            await observeMonthStartDay()
        }
        .task {
            weekStart = await (try? database.setting(.weekStart)) ?? .sunday
        }
        .task {
            await observeReminderTime()
        }
        .task {
            await observeTheme()
        }
        .task {
            await observeCustomThemes()
        }
        .task {
            await observeLaunchScreen()
        }
        .task {
            let starts = try? await database.setting(.entryStartsWithAmount)

            startsWithAmount = starts ?? false
        }
    }
}

private extension SettingsSheet {
    var header: some View {
        HStack {
            Color.clear
                .frame(width: 44, height: 44)

            Spacer()

            Text("設定")
                .displayFont(.body)
                .tracking(4)
                .foregroundStyle(Palette.accent)

            Spacer()

            RingButton(systemImage: "xmark") {
                dismiss()
            }
        }
    }

    var versionRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle")
                .sansFont(.body, weight: .light)
                .foregroundStyle(Palette.accent)
                .frame(width: 22)

            Text("バージョン")
                .textFont(.subheadline)
                .foregroundStyle(Palette.text)

            Spacer()

            Text(Bundle.main.shortVersion)
                .textFont(.footnote)
                .monospacedDigit()
                .foregroundStyle(Palette.subtext)
        }
        .frame(minHeight: 48)
    }

    func sectionTitle(_ title: String) -> some View {
        Text(title)
            .textFont(.caption2)
            .tracking(3)
            .foregroundStyle(Palette.accent)
            .padding(.leading, 8)
    }

    func pickerRow(
        _ title: String,
        systemImage: String,
        @ViewBuilder picker: () -> some View
    ) -> some View {
        let picker = picker()

        let label = HStack(spacing: 12) {
            Image(systemName: systemImage)
                .sansFont(.body, weight: .light)
                .foregroundStyle(Palette.accent)
                .frame(width: 22)

            Text(title)
                .textFont(.subheadline)
                .foregroundStyle(Palette.text)
                .lineLimit(1)
                .fixedSize()
        }

        return ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                label
                Spacer(minLength: 8)
                picker
            }
            .frame(minHeight: 52)

            VStack(alignment: .leading, spacing: 8) {
                label

                picker
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.vertical, 12)
        }
    }

    func row(
        _ title: String,
        systemImage: String,
        value: String? = nil,
        shortValue: String? = nil
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .sansFont(.body, weight: .light)
                .foregroundStyle(Palette.accent)
                .frame(width: 22)

            Text(title)
                .textFont(.subheadline)
                .foregroundStyle(Palette.text)
                .lineLimit(1)
                .layoutPriority(1)

            Spacer()

            if let value {
                ViewThatFits(in: .horizontal) {
                    Text(value)
                        .lineLimit(1)
                        .fixedSize()

                    Text(shortValue ?? value)
                        .lineLimit(1)
                        .minimumScaleFactor(Self.valueScale)
                }
                .textFont(.footnote)
                .foregroundStyle(Palette.subtext)
            }

            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(Palette.hint)
        }
        .frame(minHeight: 48)
        .contentShape(.rect)
    }
}

private extension SettingsSheet {
    static let valueScale: CGFloat = 0.7

    static let startOptions: [CapsulePicker<Bool>.Option] = [
        .init("する", value: true),
        .init("しない", value: false)
    ]

    var reminderText: String {
        reminderTime?.description ?? "オフ"
    }

    var startsWithAmountBinding: Binding<Bool> {
        Binding {
            startsWithAmount
        } set: { starts in
            startsWithAmount = starts

            Task {
                try? await database.setSetting(
                    .entryStartsWithAmount,
                    to: starts
                )
            }
        }
    }

    var weekStartBinding: Binding<Weekday> {
        Binding {
            weekStart
        } set: { day in
            weekStart = day

            Task {
                try? await database.setSetting(.weekStart, to: day)
            }
        }
    }

    func observeLaunchScreen() async {
        do {
            for try await screen in database.settingUpdates(.launchScreen) {
                launchScreen = screen
            }
        } catch {
            launchScreen = .home
        }
    }

    func observeReminderTime() async {
        do {
            for try await time in database.settingUpdates(.reminderTime) {
                reminderTime = time
            }
        } catch {
            reminderTime = nil
        }
    }

    func observeTheme() async {
        do {
            for try await theme in database.settingUpdates(.theme) {
                self.theme = theme
            }
        } catch {
            theme = .system
        }
    }

    func observeCustomThemes() async {
        do {
            for try await themes in database.customThemeUpdates() {
                customThemes = themes
            }
        } catch {
            customThemes = []
        }
    }

    func observeMonthStartDay() async {
        do {
            for try await startDay in database.settingUpdates(.monthStartDay) {
                monthStartDay = startDay
            }
        } catch {
            monthStartDay = .first
        }
    }
}

#if DEBUG
private extension SettingsSheet {
    var sampleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("開発")

            Button {
                isConfirmingSample = true
            } label: {
                row("テストデータを入れる", systemImage: "wand.and.stars")
            }
            .buttonStyle(.plain)
            .disabled(isInsertingSample)
            .padding(.horizontal, 16)
            .card()
            .confirmationDialog(
                "4 か月分の記録・予算・テンプレート・固定費を足します",
                isPresented: $isConfirmingSample,
                titleVisibility: .visible
            ) {
                Button("足す") {
                    Task {
                        await insertSample()
                    }
                }
            }

            if isInsertingSample {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }

            if let sampleMessage {
                Text(sampleMessage)
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
                    .padding(.leading, 8)
            }
        }
    }
}

private extension SettingsSheet {
    func insertSample() async {
        isInsertingSample = true
        sampleMessage = nil

        do {
            try await SampleData.insert(
                into: database,
                today: today,
                now: Date()
            )

            sampleMessage = "テストデータを入れました"
        } catch {
            sampleMessage = "テストデータを入れられませんでした"
        }

        isInsertingSample = false
    }
}
#endif

#Preview {
    if let database = try? AppDatabase.inMemory() {
        let _ = try? database.insertDefaultsIfEmpty(at: Date())

        SettingsSheet(
            database: database,
            today: LocalDate(Date(), in: .current),
            appIcon: AppIconListModel()
        )
    }
}
