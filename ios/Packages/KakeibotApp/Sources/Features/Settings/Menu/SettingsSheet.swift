import Core
import DesignSystem
import Store
import SwiftUI

public struct SettingsSheet: View {
    @State private var monthStartDay: MonthStartDay = .first
    @State private var launchScreen: LaunchScreen = .home
    @State private var weekStart: Weekday = .sunday
    @State private var reminderTime: ReminderTime?

    #if DEBUG
    @State private var isConfirmingSample = false
    @State private var isInsertingSample = false
    @State private var sampleMessage: String?
    #endif

    @Environment(\.dismiss) private var dismiss
    @Environment(\.notificationPermission) private var permission

    private let database: AppDatabase
    private let today: LocalDate

    public init(
        database: AppDatabase,
        today: LocalDate
    ) {
        self.database = database
        self.today = today
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            sectionTitle("入力")

                            VStack(spacing: 0) {
                                NavigationLink {
                                    WalletListView(database: database)
                                } label: {
                                    row("口座", systemImage: "building.columns")
                                }

                                Rectangle()
                                    .fill(Palette.gold.opacity(0.1))
                                    .frame(height: 0.5)

                                NavigationLink {
                                    CategoryListView(database: database)
                                } label: {
                                    row("カテゴリ", systemImage: "tag")
                                }

                                Rectangle()
                                    .fill(Palette.gold.opacity(0.1))
                                    .frame(height: 0.5)

                                NavigationLink {
                                    TemplateListView(database: database)
                                } label: {
                                    row(
                                        "テンプレート",
                                        systemImage: "rectangle.stack"
                                    )
                                }

                                Rectangle()
                                    .fill(Palette.gold.opacity(0.1))
                                    .frame(height: 0.5)

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
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 14)
                            .card()
                        }

                        VStack(alignment: .leading, spacing: 6) {
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

                                Rectangle()
                                    .fill(Palette.gold.opacity(0.1))
                                    .frame(height: 0.5)

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

                                Rectangle()
                                    .fill(Palette.gold.opacity(0.1))
                                    .frame(height: 0.5)

                                HStack(spacing: 12) {
                                    Image(
                                        systemName: "calendar.day.timeline.left"
                                    )
                                    .font(.system(size: 16, weight: .light))
                                    .foregroundStyle(Palette.gold)
                                    .frame(width: 22)

                                    Text("週の始まり")
                                        .font(.subheadline)
                                        .foregroundStyle(Palette.ink)

                                    Spacer()

                                    CapsulePicker(
                                        selection: weekStartBinding,
                                        options: Weekday.weekStartOptions
                                    )
                                }
                                .frame(minHeight: 52)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 14)
                            .card()
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            sectionTitle("通知")

                            NavigationLink {
                                ReminderView(
                                    model: ReminderModel(
                                        database: database,
                                        today: today,
                                        permission: permission
                                    )
                                )
                            } label: {
                                row(
                                    "記録忘れの通知",
                                    systemImage: "bell",
                                    value: reminderTime?.description ?? "オフ"
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 14)
                            .card()
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            sectionTitle("使い方")

                            HStack(spacing: 12) {
                                Image(systemName: "iphone")
                                    .font(.system(size: 16, weight: .light))
                                    .foregroundStyle(Palette.gold)
                                    .frame(width: 22)

                                Text("起動時に開く画面")
                                    .font(.subheadline)
                                    .foregroundStyle(Palette.ink)

                                Spacer()

                                CapsulePicker(
                                    selection: launchScreenBinding,
                                    options: Self.launchOptions
                                )
                            }
                            .frame(minHeight: 52)
                            .padding(.horizontal, 14)
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
                    .fill(Palette.night)
                    .ignoresSafeArea()
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
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
            launchScreen = await (try? database.setting(.launchScreen)) ?? .home
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
                .font(.system(size: 16, design: .serif))
                .tracking(4)
                .foregroundStyle(Palette.gold)

            Spacer()

            RingButton(systemImage: "xmark") {
                dismiss()
            }
        }
    }

    func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.caption2)
            .tracking(3)
            .foregroundStyle(Palette.gold)
            .padding(.leading, 6)
    }

    func row(
        _ title: String,
        systemImage: String,
        value: String? = nil
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(Palette.gold)
                .frame(width: 22)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(Palette.ink)

            Spacer()

            if let value {
                Text(value)
                    .font(.footnote)
                    .foregroundStyle(Palette.mist)
            }

            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(Palette.dusk)
        }
        .frame(minHeight: 48)
        .contentShape(.rect)
    }
}

private extension SettingsSheet {
    static let launchOptions: [CapsulePicker<LaunchScreen>.Option] =
        LaunchScreen.allCases.map { .init($0.title, value: $0) }

    var launchScreenBinding: Binding<LaunchScreen> {
        Binding {
            launchScreen
        } set: { screen in
            launchScreen = screen

            Task {
                try? await database.setSetting(.launchScreen, to: screen)
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

    func observeReminderTime() async {
        do {
            for try await time in database.settingUpdates(.reminderTime) {
                reminderTime = time
            }
        } catch {
            reminderTime = nil
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
        VStack(alignment: .leading, spacing: 6) {
            sectionTitle("開発")

            Button {
                isConfirmingSample = true
            } label: {
                row("テストデータを入れる", systemImage: "wand.and.stars")
            }
            .buttonStyle(.plain)
            .disabled(isInsertingSample)
            .padding(.horizontal, 14)
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
                    .font(.footnote)
                    .foregroundStyle(Palette.mist)
                    .padding(.leading, 6)
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
            today: LocalDate(Date(), in: .current)
        )
    }
}
