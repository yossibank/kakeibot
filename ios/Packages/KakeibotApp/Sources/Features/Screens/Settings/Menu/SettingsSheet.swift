import Core
import DesignSystem
import Store
import SwiftUI

public struct SettingsSheet: View {
    @State var monthStartDay: MonthStartDay = .first
    @State var launchScreen: LaunchScreen = .home
    @State var weekStart: Weekday = .sunday
    @State var reminderTime: ReminderTime?
    @State var authorization: NotificationAuthorization = .allowed
    @State var theme: ThemeChoice = .system
    @State var customThemes: [Theme] = []
    @State var syncStatus = SyncStatus(isEnabled: false, stopReason: nil)

    #if DEBUG
    @State var isConfirmingSample = false
    @State var isInsertingSample = false
    @State var sampleMessage: String?
    #endif

    @Environment(\.dismiss) var dismiss
    @Environment(\.notificationPermission) var permission
    @Environment(\.syncCloud) var syncCloud
    @Environment(\.themeStyle) var themeStyle

    let database: AppDatabase
    let today: LocalDate
    let appIcon: AppIconListModel

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
                        recordSection

                        periodSection

                        funSection

                        lookSection

                        usageSection

                        dataSection

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
            authorization = await permission.authorization()
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
            await observeSync()
        }
    }
}

private extension SettingsSheet {
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

    func observeSync() async {
        do {
            for try await status in database.syncStatusUpdates() {
                syncStatus = status
            }
        } catch {
            syncStatus = SyncStatus(isEnabled: false, stopReason: nil)
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

#Preview {
    if let database = try? AppDatabase.inMemory() {
        let _ = try? database.insertDefaultsIfEmpty(at: Date())
        let today = LocalDate(Date(), in: .current)

        SettingsSheet(database: database, today: today, appIcon: AppIconListModel())
    }
}
