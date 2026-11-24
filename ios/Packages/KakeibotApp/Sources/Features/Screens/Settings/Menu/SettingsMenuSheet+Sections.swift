import Core
import DesignSystem
import FeatureModels
import Store
import SwiftUI

extension SettingsMenuSheet {
    var recordSection: some View {
        section("記録に使うもの") {
            NavigationLink {
                WalletListView(parts: parts)
            } label: {
                row("口座", systemImage: "building.columns")
            }

            Hairline()

            NavigationLink {
                CategoryListView(parts: parts)
            } label: {
                row("カテゴリ", systemImage: "tag")
            }

            Hairline()

            NavigationLink {
                TemplateListView(parts: parts)
            } label: {
                row("テンプレート", systemImage: "rectangle.stack")
            }
        }
    }

    var budgetSection: some View {
        section("予算と期間") {
            NavigationLink {
                BudgetListView(
                    model: BudgetListModel(
                        parts: parts,
                        today: today
                    )
                )
            } label: {
                row("予算", systemImage: "chart.bar")
            }

            Hairline()

            NavigationLink {
                RecurringListView(
                    board: RecurringBoard(
                        parts: parts,
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
                        parts: parts,
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
                StampListView(parts: parts)
            } label: {
                row("スタンプ", systemImage: "seal")
            }

            Hairline()

            NavigationLink {
                RewardRuleListView(parts: parts)
            } label: {
                row("ごほうびの決まり", systemImage: "gift")
            }
        }
    }

    var homeSection: some View {
        section("ホームと通知") {
            NavigationLink {
                HomeSectionListView(
                    model: HomeSectionListModel(parts: parts),
                    parts: parts
                )
            } label: {
                row("ホームに出すもの", systemImage: "rectangle.grid.1x2")
            }

            Hairline()

            NavigationLink {
                LaunchScreenView(model: LaunchScreenModel(parts: parts))
            } label: {
                row("起動時に開く画面", systemImage: "iphone", value: model.input.launchScreen.title)
            }

            Hairline()

            NavigationLink {
                ReminderView(
                    model: ReminderModel(
                        parts: parts,
                        today: today,
                        time: model.input.reminderTime,
                        authorization: authorization,
                        permission: permission
                    )
                )
            } label: {
                row("記録忘れの通知", systemImage: "bell", value: reminderText)
            }

            if model.input.usesFun == false {
                SettingsMenuRewardStartRow(parts: parts)
            }
        }
    }

    var lookSection: some View {
        section("見た目") {
            NavigationLink {
                ThemeListView(parts: parts, appIcon: appIcon)
            } label: {
                row(
                    "テーマ",
                    systemImage: "paintpalette",
                    value: model.input.theme.title(in: model.input.customThemes)
                )
            }

            Hairline()

            NavigationLink {
                AppIconListView(model: appIcon, parts: parts)
            } label: {
                row(
                    "アプリアイコン",
                    systemImage: "app.badge",
                    value: appIcon.input.current.title
                )
            }

            Hairline()

            NavigationLink {
                ThemeStyleTextView(model: ThemeStyleModel(parts: parts))
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
                ThemeStyleLookView(model: ThemeStyleModel(parts: parts))
            } label: {
                row("形と動き", systemImage: "square.on.circle") {
                    ThemeStyleMarks()
                }
            }
        }
    }

    var proSection: some View {
        VStack(spacing: 0) {
            NavigationLink {
                ProView(model: ProPurchaseModel(store: proStore))
            } label: {
                row("Pro", systemImage: "sparkles", value: proText)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .card()
    }

    var dataSection: some View {
        section("データ") {
            NavigationLink {
                SyncView(
                    model: SyncModel(
                        parts: parts,
                        cloud: syncCloud
                    )
                )
            } label: {
                SettingsMenuSyncRow(status: model.input.syncStatus)
            }

            Hairline()

            NavigationLink {
                BackupView(
                    model: BackupModel(
                        parts: parts,
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
                WidgetGuideView(parts: parts)
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
        PeriodText.startDay(model.input.monthStartDay)
    }

    var reminderText: String {
        ReminderModel.rowText(time: model.input.reminderTime, authorization: authorization)
    }

    var proText: String {
        isPro ? "購入済み" : "詳しく見る"
    }

    var backupText: String? {
        model.backupText()
    }

    var weekStartBinding: Binding<Weekday> {
        Binding {
            weekStart.output.value
        } set: { day in
            Task {
                await weekStart.choose(day)
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
