import Core
import DesignSystem
import Store
import SwiftUI

extension SettingsSheet {
    var header: some View {
        HStack {
            Color.clear
                .frame(width: 44, height: 44)

            Spacer()

            SheetTitle("設定")

            Spacer()

            RingButton(systemImage: "xmark") {
                dismiss()
            }
        }
    }

    var recordSection: some View {
        section("記録") {
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
                row("テンプレート", systemImage: "rectangle.stack")
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
        }
    }

    var periodSection: some View {
        section("期間と予算") {
            NavigationLink {
                MonthStartDayView(
                    model: MonthStartDayModel(
                        database: database,
                        today: today
                    )
                )
            } label: {
                row("月の始まり", systemImage: "calendar", value: monthStartDayText)
            }

            Hairline()

            pickerRow("週の始まり", systemImage: "calendar.day.timeline.left") {
                CapsulePicker(selection: weekStartBinding, options: Weekday.weekStartOptions)
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
        }
    }

    var funSection: some View {
        section("楽しみ") {
            NavigationLink {
                StampListView(database: database)
            } label: {
                row("スタンプ", systemImage: "seal")
            }

            Hairline()

            NavigationLink {
                RewardRuleListView(database: database)
            } label: {
                row("ごほうび", systemImage: "gift")
            }
        }
    }

    var lookSection: some View {
        section("見た目") {
            NavigationLink {
                ThemeListView(database: database, appIcon: appIcon)
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
                ThemeStyleView(model: ThemeStyleModel(database: database))
            } label: {
                row(
                    "文字と角の丸み",
                    systemImage: "textformat",
                    value: themeStyle.title,
                    shortValue: themeStyle.shortTitle
                )
            }
        }
    }

    var usageSection: some View {
        section("使い方") {
            NavigationLink {
                LaunchScreenView(model: LaunchScreenModel(database: database))
            } label: {
                row("起動時に開く画面", systemImage: "iphone", value: launchScreen.title)
            }

            Hairline()

            NavigationLink {
                HomeSectionsView(model: HomeSectionsModel(database: database), database: database)
            } label: {
                row("ホームに出すもの", systemImage: "square.stack")
            }

            Hairline()

            NavigationLink {
                ReminderView(
                    model: ReminderModel(
                        database: database,
                        today: today,
                        time: reminderTime,
                        authorization: authorization,
                        permission: permission
                    )
                )
            } label: {
                row("記録忘れの通知", systemImage: "bell", value: reminderText)
            }
        }
    }

    var dataSection: some View {
        section("データとアプリ") {
            NavigationLink {
                SyncView(
                    model: SyncModel(
                        database: database,
                        cloud: syncCloud
                    )
                )
            } label: {
                row("iCloud 同期", systemImage: "icloud", value: syncText)
            }

            Hairline()

            NavigationLink {
                BackupView(
                    model: BackupModel(
                        database: database,
                        permission: permission
                    )
                )
            } label: {
                row("バックアップ", systemImage: "externaldrive")
            }

            Hairline()

            versionRow
        }
    }
}

private extension SettingsSheet {
    var monthStartDayText: String {
        PeriodText.startDay(monthStartDay)
    }

    var reminderText: String {
        reminderTime?.description ?? "オフ"
    }

    var syncText: String {
        isSyncOn ? "オン" : "オフ"
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
}
