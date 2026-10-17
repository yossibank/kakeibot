import Core
import DesignSystem
import Store
import SwiftUI

struct SettingsSheet: View {
    @State private var monthStartDay: MonthStartDay = .first
    @State private var launchScreen: LaunchScreen = .home
    @State private var weekStart: Weekday = .sunday

    @Environment(\.dismiss) private var dismiss

    let database: AppDatabase

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                header

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
                            row("テンプレート", systemImage: "rectangle.stack")
                        }
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

                VStack(alignment: .leading, spacing: 6) {
                    sectionTitle("期間と予算")

                    VStack(spacing: 0) {
                        NavigationLink {
                            MonthStartDayView(
                                model: MonthStartDayModel(
                                    database: database,
                                    today: LocalDate(Date(), in: .current)
                                )
                            )
                        } label: {
                            row(
                                "月の始まり",
                                systemImage: "calendar",
                                value: PeriodText.startDay(monthStartDay)
                            )
                        }

                        Rectangle()
                            .fill(Palette.gold.opacity(0.1))
                            .frame(height: 0.5)

                        NavigationLink {
                            BudgetListView(
                                model: BudgetListModel(
                                    database: database,
                                    today: LocalDate(Date(), in: .current)
                                )
                            )
                        } label: {
                            row("予算", systemImage: "chart.bar")
                        }

                        Rectangle()
                            .fill(Palette.gold.opacity(0.1))
                            .frame(height: 0.5)

                        HStack(spacing: 12) {
                            Image(systemName: "calendar.day.timeline.left")
                                .font(.system(size: 16, weight: .light))
                                .foregroundStyle(Palette.gold)
                                .frame(width: 22)

                            Text("週の始まり")
                                .font(.subheadline)
                                .foregroundStyle(Palette.ink)

                            Spacer()

                            CapsulePicker(
                                selection: weekStartBinding,
                                options: Self.weekStartOptions
                            )
                        }
                        .frame(minHeight: 52)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 14)
                    .card()
                }
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
            weekStart = await (try? database.weekStart()) ?? .sunday
        }
        .task {
            launchScreen = await (try? database.launchScreen()) ?? .home
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

    static let weekStartOptions: [CapsulePicker<Weekday>.Option] = [
        .init("日曜", value: .sunday),
        .init("月曜", value: .monday)
    ]

    var launchScreenBinding: Binding<LaunchScreen> {
        Binding {
            launchScreen
        } set: { screen in
            launchScreen = screen

            Task {
                try? await database.setLaunchScreen(screen)
            }
        }
    }

    var weekStartBinding: Binding<Weekday> {
        Binding {
            weekStart
        } set: { day in
            weekStart = day

            Task {
                try? await database.setWeekStart(day)
            }
        }
    }

    func observeMonthStartDay() async {
        do {
            for try await startDay in database.monthStartDayUpdates() {
                monthStartDay = startDay
            }
        } catch {
            monthStartDay = .first
        }
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        let _ = try? database.insertDefaultsIfEmpty(at: Date())
        SettingsSheet(database: database)
    }
}
