import Core
import DesignSystem
import Store
import SwiftUI

public struct SettingsMenuSheet: View {
    @State var monthStartDay: MonthStartDay = .first
    @State var launchScreen: LaunchScreen = .home
    @State var reminderTime: ReminderTime?
    @State var authorization: NotificationAuthorization = .allowed
    @State var theme: ThemeChoice = .system
    @State var customThemes: [Theme] = []
    @State var syncStatus = SyncStatus.off
    @State var backupExportedAt: Date?
    @State var firstEntryCreatedAt: Date?
    @State var weekStart: SettingsMenuValueModel<Weekday>
    @State var entryStart: SettingsMenuValueModel<Bool>
    @State var recordReset: SettingsMenuResetModel
    @State var isConfirmingReset = false
    @State var isListShown = false

    #if DEBUG
    @State var isConfirmingSample = false
    @State var isInsertingSample = false
    @State var sampleMessage: String?
    #endif

    @Environment(\.isPro) var isPro
    @Environment(\.notificationPermission) var permission
    @Environment(\.openURL) var openURL
    @Environment(\.proStore) var proStore
    @Environment(\.scenePhase) var scenePhase
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
        _weekStart = State(
            initialValue: SettingsMenuValueModel(
                database: database,
                key: .weekStart
            )
        )

        _entryStart = State(
            initialValue: SettingsMenuValueModel(
                database: database,
                key: .entryStartsWithAmount
            )
        )

        _recordReset = State(initialValue: SettingsMenuResetModel(database: database))

        self.database = database
        self.today = today
        self.appIcon = appIcon
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                SettingsBackHeader("設定")
                    .environment(\.isSettingsSheetRoot, true)

                ScrollView {
                    if isListShown {
                        sectionList
                            .transition(.opacity)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background {
                Backdrop()
                    .ignoresSafeArea()
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .errorBanner(weekStart.errorNotice) {
            weekStart.errorNotice.clear()
        }
        .errorBanner(entryStart.errorNotice) {
            entryStart.errorNotice.clear()
        }
        .errorBanner(recordReset.errorNotice) {
            recordReset.errorNotice.clear()
        }
        .confirmation(
            isPresented: $isConfirmingReset,
            systemImage: "trash",
            title: "記録をすべて削除しますか",
            message: recordReset.message(isSyncing: syncStatus.isEnabled),
            keepTitle: "やめる",
            confirmTitle: "削除する"
        ) {
            Task {
                await recordReset.deleteAll()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task {
                    authorization = await permission.authorization()
                }
            }
        }
        .task {
            try? await Task.sleep(for: Self.listDelay)

            withAnimation(.easeOut(duration: 0.2)) {
                isListShown = true
            }
        }
        .task {
            await observeMonthStartDay()
        }
        .task {
            await weekStart.load()
        }
        .task {
            await entryStart.load()
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
        .task {
            await observeBackupExportedAt()
        }
        .task {
            firstEntryCreatedAt = try? await database.entryHistory().firstCreatedAt
        }
    }
}

private extension SettingsMenuSheet {
    static let listDelay: Duration = .milliseconds(30)

    var sectionList: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            recordSection

            budgetSection

            funSection

            homeSection

            lookSection

            dataSection

            aboutSection

            #if DEBUG
            sampleSection
            #endif

            versionText
                .padding(.top, 8)
        }
        .padding(.bottom, 24)
    }
}

private extension SettingsMenuSheet {
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
            syncStatus = .off
        }
    }

    func observeBackupExportedAt() async {
        do {
            for try await date in database.settingUpdates(.backupExportedAt) {
                backupExportedAt = date
            }
        } catch {
            backupExportedAt = nil
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

        SettingsMenuSheet(database: database, today: today, appIcon: AppIconListModel())
    }
}
