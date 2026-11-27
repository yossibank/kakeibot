import CloudKit
import Core
import DesignSystem
import FeatureModels
import Features
import Notifications
import SwiftUI
import Sync
import UIKit
import VisionKit

public struct RootView: View {
    @State private var model = AppModel.live()

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    public init() {}

    public var body: some View {
        ZStack {
            content
                .overlay {
                    Color.clear
                        .padding(.leading, MainView.noticeLeading(hasSidebar: hasSidebar))
                        .errorBanner(model.state.notice, bottom: noticeBottom)
                }

            if model.state.reveal.curtain.isShown {
                AppLaunchView(
                    state: model.state,
                    palette: themePalette,
                    isReady: isLaunchReady
                )
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

            if phase == .active {
                model.perform {
                    await $0.refreshDay()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            model.perform {
                await $0.refreshDay()
            }
        }
        .environment(
            \.notificationPermission,
            .live {
                await model.rescheduleNotifications()
            }
        )
        .environment(\.syncCloud, .live)
        .environment(\.proStore, model.screenProStore())
        .environment(\.isPro, model.input.isPro)
        .environment(\.canScanReceipt, VNDocumentCameraViewController.isSupported)
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
        switch model.state.launch {
        case .opening:
            ProgressView()

        case let .onboarding(opened):
            OnboardingView(
                parts: opened.parts,
                today: model.input.today
            ) {
                withAnimation(.snappy) {
                    model.finishOnboarding()
                }
            }
            .transition(.opacity)

        case let .ready(opened):
            MainView(
                parts: opened.parts,
                today: model.input.today,
                route: model.route,
                isRevealed: !model.state.reveal.curtain.isShown
            ) {
                model.finishRoute()
            } onLoad: {
                model.state.markHomeLoaded()
            }
            .task(id: model.observationID(model.input.today)) {
                await model.observeNotifications()
            }
            .task(id: model.observationID(model.input.today)) {
                await model.observeWidgets()
            }
            .task(id: model.observationID(model.input.today)) {
                await model.observeSync()
            }
            .task(id: model.observationID(model.input.syncActivity)) {
                await model.syncChanges()
            }
            .task(id: model.observationID(model.receivedShareCount)) {
                await model.acceptShares()
            }
            .task {
                await model.observePro()
            }

        case .failed:
            ContentUnavailableView {
                Label("データを開けませんでした", systemImage: "exclamationmark.triangle")
            } actions: {
                Button("もう一度試す") {
                    model.perform {
                        await $0.retryOpen()
                    }
                }
            }
        }
    }
}

private extension RootView {
    var isLaunchReady: Bool {
        switch model.state.launch {
        case .opening: false
        case .ready: model.state.reveal.isHomeLoaded
        case .onboarding, .failed: true
        }
    }

    var hasSidebar: Bool {
        switch model.state.launch {
        case .ready: MainView.hasSidebar(horizontalSizeClass)
        case .opening, .onboarding, .failed: false
        }
    }

    var noticeBottom: CGFloat {
        switch model.state.launch {
        case .ready: MainView.noticeBottom(hasSidebar: hasSidebar)
        case .opening, .onboarding, .failed: 12
        }
    }

    var shownLook: ThemeLook {
        model.state.reveal.curtain.isRevealed ? model.input.look : .followsDevice
    }

    var themePalette: ThemePalette {
        let isDark = colorScheme == .dark
        return model.input.look.palette(isDark: isDark)
    }

    var shownPalette: ThemePalette {
        let isDark = colorScheme == .dark
        return shownLook.palette(isDark: isDark)
    }

    var shownStyle: ThemeStyle {
        model.state.reveal.curtain.isRevealed ? model.input.style : .standard
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
    } summary: {
        try await SyncEngine.cloudSummary()
    } deleteData: {
        try await SyncEngine.deleteCloudData()
    } createShare: { walletID, title in
        _ = try await SyncEngine.share(walletID: walletID, title: title)
    } showShare: { walletID, title, onStop, onFail in
        let share = try await SyncEngine.share(walletID: walletID, title: title)

        SyncShareSheet.present(
            share,
            title: title,
            onStop: onStop,
            onFail: onFail
        )
    } participants: { walletID, title in
        let share = try await SyncEngine.share(walletID: walletID, title: title)
        return share.participants.compactMap(SyncParticipant.init)
    } deleteShare: { walletID in
        try await SyncEngine.deleteShare(walletID: walletID)
    } leaveShare: { walletID, ownerName in
        try await SyncEngine.leaveShare(walletID: walletID, ownerName: ownerName)
    }
}

extension View {
    func warmsUpInput() -> some View {
        background(InputWarmup())
    }
}

#Preview {
    RootView()
}
