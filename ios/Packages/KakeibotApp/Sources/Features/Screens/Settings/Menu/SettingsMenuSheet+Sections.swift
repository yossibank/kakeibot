import Core
import DesignSystem
import Store
import SwiftUI

extension SettingsMenuSheet {
    var recordSection: some View {
        section("記録に使うもの") {
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

            switchRow(
                "金額の入力から始める",
                systemImage: "keyboard",
                isOn: entryStartBinding
            )
        }
    }

    var budgetSection: some View {
        section("予算と期間") {
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
                row("ごほうびの決まり", systemImage: "gift")
            }
        }
    }

    var homeSection: some View {
        section("ホームと通知") {
            NavigationLink {
                HomeSectionListView(
                    model: HomeSectionListModel(database: database),
                    database: database
                )
            } label: {
                row("ホームに出すもの", systemImage: "rectangle.grid.1x2")
            }

            Hairline()

            NavigationLink {
                LaunchScreenView(model: LaunchScreenModel(database: database))
            } label: {
                row("起動時に開く画面", systemImage: "iphone", value: launchScreen.title)
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
                ThemeStyleTextView(model: ThemeStyleModel(database: database))
            } label: {
                row(
                    "文字",
                    systemImage: "textformat",
                    value: themeStyle.textTitle,
                    shortValue: themeStyle.shortTextTitle
                )
            }

            Hairline()

            NavigationLink {
                ThemeStyleLookView(model: ThemeStyleModel(database: database))
            } label: {
                row("形と動き", systemImage: "square.on.circle") {
                    ThemeStyleMarks()
                }
            }
        }
    }

    var dataSection: some View {
        section("データ") {
            NavigationLink {
                ProView(model: ProPurchaseModel(store: proStore))
            } label: {
                row("Pro", systemImage: "sparkles", value: proText)
            }

            Hairline()

            NavigationLink {
                SyncView(
                    model: SyncModel(
                        database: database,
                        cloud: syncCloud
                    )
                )
            } label: {
                row("同期と共有", systemImage: "icloud", value: syncText)
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
                row("バックアップ", systemImage: "externaldrive", value: backupText)
            }

            Hairline()

            Button {
                Task {
                    isConfirmingReset = await recordReset.prepare()
                }
            } label: {
                row("記録をすべて削除", systemImage: "trash", tint: Palette.rose)
            }
        }
    }

    var aboutSection: some View {
        section("このアプリについて") {
            NavigationLink {
                WidgetGuideView()
            } label: {
                row("ウィジェットの置き方", systemImage: "square.grid.2x2")
            }

            Hairline()

            Button {
                open(SettingsMenuLink.contact())
            } label: {
                row("お問い合わせ", systemImage: "envelope", trailingImage: "arrow.up.right")
            }

            Hairline()

            Button {
                open(SettingsMenuLink.review)
            } label: {
                row("レビューを書く", systemImage: "star", trailingImage: "arrow.up.right")
            }
        }
    }
}

private extension SettingsMenuSheet {
    var monthStartDayText: String {
        PeriodText.startDay(monthStartDay)
    }

    var reminderText: String {
        ReminderModel.rowText(time: reminderTime, authorization: authorization)
    }

    var proText: String {
        isPro ? "購入済み" : "詳しく見る"
    }

    var syncText: String {
        switch (syncStatus.isEnabled, syncStatus.stopReason) {
        case (true, _): "オン"
        case (false, .some): "切れました"
        case (false, nil): "オフ"
        }
    }

    var backupText: String? {
        guard !syncStatus.isEnabled else {
            return nil
        }

        return BackupModel.exportAgeText(
            exportedAt: backupExportedAt,
            firstCreatedAt: firstEntryCreatedAt,
            now: Date()
        )
    }

    var weekStartBinding: Binding<Weekday> {
        Binding {
            weekStart.value
        } set: { day in
            Task {
                await weekStart.choose(day)
            }
        }
    }

    var entryStartBinding: Binding<Bool> {
        Binding {
            entryStart.value
        } set: { isOn in
            Task {
                await entryStart.choose(isOn)
            }
        }
    }

    func open(_ url: URL?) {
        guard let url else {
            return
        }

        openURL(url)
    }
}
