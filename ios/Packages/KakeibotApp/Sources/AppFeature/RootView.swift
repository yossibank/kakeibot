import Core
import DesignSystem
import Features
import Notifications
import Store
import SwiftUI
import Sync
import UIKit

public struct RootView: View {
    @State private var model = AppModel(openDatabase: AppDatabase.appGroup)
    @State private var isLaunching = true
    @State private var isRevealed = false
    @State private var isHomeLoaded = false
    @State private var foreground = ForegroundReturn()

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    public var body: some View {
        ZStack {
            content

            if isLaunching {
                LaunchView(
                    palette: themePalette,
                    isReady: isLaunchReady
                ) {
                    isRevealed = true
                } onFinish: {
                    isLaunching = false
                }
            }
        }
        .task {
            await model.open()
        }
        .task(id: model.observationID(model.hasDatabase)) {
            await model.observeTheme()
        }
        .onOpenURL { url in
            model.open(url)
        }
        .onChange(of: scenePhase) { _, phase in
            model.changeScene(to: phase)

            if foreground.receive(phase) {
                model.returnToForeground()
            }

            if phase == .active {
                Task {
                    await model.refreshDay()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            Task {
                await model.refreshDay()
            }
        }
        .environment(
            \.notificationPermission,
            .live {
                await model.rescheduleNotifications()
            }
        )
        .environment(\.syncCloud, .live)
        .palette(shownLook)
        .environment(\.palette, shownPalette)
        .environment(\.themeStyle, shownStyle)
        .font(shownStyle.bodyFont)
        .warmsUpInput()
    }
}

private extension RootView {
    @ViewBuilder
    var content: some View {
        switch model.launch {
        case .opening:
            ProgressView()
        case let .onboarding(database):
            OnboardingView(
                database: database,
                today: model.today
            ) {
                withAnimation(.snappy) {
                    model.finishOnboarding()
                }
            }
            .transition(.opacity)
        case let .ready(database):
            MainView(
                database: database,
                today: model.today,
                route: model.route,
                isRevealed: !isLaunching
            ) {
                model.finishRoute()
            } onLoad: {
                isHomeLoaded = true
            }
            .errorBanner(model.notice, bottom: MainView.noticeBottom) {
                model.notice.clear()
            }
            .task(id: model.observationID(model.today)) {
                await model.observeNotifications(in: database)
            }
            .task(id: model.observationID(model.today)) {
                await model.observeWidgets(in: database)
            }
            .task(id: model.observationID(model.today)) {
                await model.observeSync(in: database)
            }
            .task(id: model.observationID(model.syncActivity)) {
                await model.syncChanges(in: database)
            }
            .task(id: model.observationID(model.pendingShareCount)) {
                await model.acceptShares(in: database)
            }
        case .failed:
            ContentUnavailableView {
                Label("データを開けませんでした", systemImage: "exclamationmark.triangle")
            } actions: {
                Button("もう一度試す") {
                    Task {
                        await model.retryOpen()
                    }
                }
            }
        }
    }
}

private extension RootView {
    var isLaunchReady: Bool {
        switch model.launch {
        case .opening: false
        case .ready: isHomeLoaded
        case .onboarding, .failed: true
        }
    }

    var shownLook: ThemeLook {
        isRevealed ? model.look : .followsDevice
    }

    var themePalette: ThemePalette {
        let isDark = colorScheme == .dark
        return model.look.palette(isDark: isDark)
    }

    var shownPalette: ThemePalette {
        let isDark = colorScheme == .dark
        return shownLook.palette(isDark: isDark)
    }

    var shownStyle: ThemeStyle {
        isRevealed ? model.style : .standard
    }
}

extension NotificationPermission {
    static func live(reschedule: @escaping Reschedule) -> Self {
        Self {
            await LiveNotificationCenter().authorization()
        } request: {
            await LiveNotificationCenter().requestAuthorization()
        } reschedule: {
            await reschedule()
        }
    }
}

extension SyncCloud {
    static let live = Self {
        await SyncAccount(SyncEngine.accountStatus())
    } hasData: {
        try await SyncEngine.hasCloudData()
    } deleteData: {
        try await SyncEngine.deleteCloudData()
    } createShare: { walletID, title in
        let zoneName = SyncZone.wallet(walletID)
        _ = try await SyncEngine.share(zoneName: zoneName, title: title)
    } showShare: { walletID, title, onStop in
        let zoneName = SyncZone.wallet(walletID)
        let share = try await SyncEngine.share(zoneName: zoneName, title: title)

        SyncShareSheet.present(share, title: title, onStop: onStop)
    } deleteShare: { walletID in
        let zoneName = SyncZone.wallet(walletID)
        try await SyncEngine.deleteShare(zoneName: zoneName)
    }
}

extension View {
    func warmsUpInput() -> some View {
        background(InputWarmup())
    }
}

private struct InputWarmup: UIViewRepresentable {
    func makeUIView(context: Context) -> WarmupView {
        WarmupView()
    }

    func updateUIView(
        _ uiView: WarmupView,
        context: Context
    ) {}
}

private final class WarmupView: UIView {
    private var isWarmedUp = false

    override func didMoveToWindow() {
        super.didMoveToWindow()

        guard
            let window,
            !isWarmedUp
        else {
            return
        }

        let field = UITextField()

        isWarmedUp = true

        window.addSubview(field)
        field.becomeFirstResponder()
        field.resignFirstResponder()
        field.removeFromSuperview()
        UISelectionFeedbackGenerator().prepare()
        UIImpactFeedbackGenerator(style: .light).prepare()
    }
}

#Preview {
    RootView()
}
