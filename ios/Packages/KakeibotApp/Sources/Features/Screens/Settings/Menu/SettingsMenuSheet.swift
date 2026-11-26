import Core
import DesignSystem
import FeatureModels
import SwiftUI

public struct SettingsMenuSheet: View {
    @State var model: SettingsMenuModel
    @State var weekStart: SettingsMenuValueModel<Weekday>
    @State var recordReset: SettingsMenuResetModel

    #if DEBUG
    @State var sample: SettingsMenuSampleModel
    #endif

    @Environment(\.isPro) var isPro
    @Environment(\.notificationPermission) var permission
    @Environment(\.openURL) var openURL
    @Environment(\.proStore) var proStore
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.syncCloud) var syncCloud
    @Environment(\.themeStyle) var themeStyle

    let parts: ScreenParts
    let today: LocalDate
    let appIcon: AppIconListModel

    public init(
        parts: ScreenParts,
        today: LocalDate,
        appIcon: AppIconListModel
    ) {
        let model = SettingsMenuModel(parts: parts)

        _model = State(initialValue: model)
        _weekStart = State(initialValue: model.weekStartModel())
        _recordReset = State(initialValue: SettingsMenuResetModel(parts: parts))

        #if DEBUG
        _sample = State(initialValue: model.sampleModel())
        #endif

        self.parts = parts
        self.today = today
        self.appIcon = appIcon
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                SettingsBackHeader("設定")
                    .environment(\.isSettingsSheetRoot, true)

                sections
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .backdrop()
            .toolbar(.hidden, for: .navigationBar)
        }
        .errorBanner(Bindable(weekStart.state).errorNotice)
        .errorBanner(Bindable(recordReset.state).errorNotice)
        .confirmation(
            isPresented: Bindable(recordReset.state).prompt[.deleteAll],
            systemImage: "trash",
            title: "記録をすべて削除しますか",
            message: recordReset.output.message(isSyncing: model.input.syncStatus.isEnabled),
            keepTitle: "やめる",
            confirmTitle: "削除する"
        ) {
            recordReset.perform {
                await $0.deleteAll()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                model.perform { [permission] in
                    await $0.loadAuthorization(permission)
                }
            }
        }
        .task {
            await model.run()
        }
        .task {
            await weekStart.load()
        }
        .task {
            await model.loadAuthorization(permission)
        }
    }
}

private extension SettingsMenuSheet {
    var sections: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                recordSection

                budgetSection

                if model.input.usesFun == true {
                    funSection
                }

                homeSection

                lookSection

                dataSection

                aboutSection

                proSection

                #if DEBUG
                sampleSection
                #endif

                versionText
                    .padding(.top, 8)
            }
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }
}

#Preview {
    if let parts = ScreenParts.preview() {
        let today = LocalDate(Date(), in: .current)

        SettingsMenuSheet(
            parts: parts,
            today: today,
            appIcon: AppIconListModel()
        )
    }
}
