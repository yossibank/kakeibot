import Core
import DesignSystem
import FeatureModels
import SwiftUI

public struct SyncView: View {
    @State var model: SyncModel
    @State var leaving: JoinedShare?
    @State var stopping: WalletShare?
    @State var proOffer: ProOffer?

    @Environment(\.isPro) var isPro

    @Environment(\.scenePhase) private var scenePhase

    public init(model: SyncModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        VStack(spacing: 16) {
            SettingsBackHeader("同期と共有", hint: hint)

            SyncIntroCard(hint: hint)

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(spacing: 0) {
                            HStack(spacing: 12) {
                                Text("同期する")
                                    .textFont(.subheadline)
                                    .foregroundStyle(Palette.text)

                                Spacer(minLength: 0)

                                CapsulePicker(selection: onBinding, options: Self.onOptions)
                            }
                            .frame(minHeight: 58)
                            .disabled(model.state.isWorking || model.output
                                .isSwitching || !canChange)

                            if let progress = model.output.progress {
                                Hairline()

                                status(progress)
                                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            }
                        }
                        .padding(.horizontal, 16)
                        .card()

                        SettingsCaption(model.output.footnote)
                    }

                    if !model.input.shares.isEmpty {
                        sharingSection
                    }

                    if !model.input.joined.isEmpty {
                        joinedSection
                    }
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, SettingsSpacing.side)
        .padding(.top, SettingsSpacing.top)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .errorBanner(Bindable(model.state).errorNotice)
        .backdrop()
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                model.perform {
                    await $0.refreshAccount()
                }
            }
        }
        .task {
            await model.load()
        }
        .task {
            await model.observe()
        }
        .confirmation(
            isPresented: isLeavingBinding,
            systemImage: "person.crop.circle.badge.minus",
            title: "共有から抜けますか",
            message: "この \(DeviceName.current) から口座と記録が消えます。自分の口座との振替は、支出と収入にして残します",
            keepTitle: "やめる",
            confirmTitle: "抜ける"
        ) { [leaving] in
            leave(leaving)
        }
        .confirmation(
            isPresented: isStoppingBinding,
            systemImage: "person.2.slash",
            title: "共有を終えますか",
            message: "相手の端末から、この口座と記録が消えます。この \(DeviceName.current) には残ります",
            keepTitle: "やめる",
            confirmTitle: "共有を終える"
        ) { [stopping] in
            stopSharing(stopping)
        }
        .overlay {
            if let choice = model.state.choice {
                SyncChoiceCard(
                    choice: choice,
                    onUseLocal: useLocalData,
                    onUseCloud: useCloudData,
                    onKeep: model.cancelChoice
                )
            } else if let invitation = model.state.invitation {
                SyncInviteCard(
                    item: invitation,
                    onInvite: confirmInvitation,
                    onCancel: model.cancelInvitation
                )
            } else if let opened = model.state.opened {
                SyncSharedCard(
                    item: opened,
                    participants: model.output.participants,
                    isFailed: model.output.isParticipantsFailed,
                    onInvite: inviteMore,
                    onStop: {
                        askToStop(opened)
                    },
                    onClose: model.closeOpened
                )
            }
        }
        .animation(.snappy(duration: 0.25), value: model.state.choice)
        .animation(.snappy(duration: 0.25), value: model.state.invitation)
        .animation(.snappy(duration: 0.25), value: model.state.opened)
        .proOffer(proOffer?.feature) {
            proOffer = nil
        } onUnlock: {
            unlock()
        }
        .haptic(.selection, trigger: model.output.isChoosing) { _, new in
            new
        }
        .haptic(.success, trigger: model.output.progress) { old, new in
            Self.hasFinishedSyncing(from: old, to: new)
        }
    }
}

extension SyncView {
    enum ProOffer: Equatable {
        case sync
        case share(WalletShare)

        var feature: String {
            switch self {
            case .sync: "端末間の同期"
            case .share: "家族との共有"
            }
        }
    }
}

private extension SyncView {
    @ViewBuilder
    func status(_ progress: SyncProgress) -> some View {
        if progress.isProblem {
            warning(progress.message)
        } else {
            HStack(spacing: 8) {
                if progress.isBusy {
                    ProgressView()
                        .controlSize(.mini)
                } else {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(Palette.accent)
                }

                Text(progress.message)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .textFont(.footnote)
            .foregroundStyle(Palette.subtext)
            .padding(.vertical, 12)
        }
    }

    func warning(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "exclamationmark.triangle")

            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .textFont(.footnote)
        .foregroundStyle(Palette.rose)
        .padding(.vertical, 12)
    }
}

private extension SyncView {
    static let onOptions: [CapsulePicker<Bool>.Option] = [
        .init("オフ", value: false),
        .init("オン", value: true)
    ]

    var canChange: Bool {
        model.input.isOn || model.output.isAvailable
    }

    var isLeavingBinding: Binding<Bool> {
        Binding {
            leaving != nil
        } set: { isPresented in
            if !isPresented {
                leaving = nil
            }
        }
    }

    var isStoppingBinding: Binding<Bool> {
        Binding {
            stopping != nil
        } set: { isPresented in
            if !isPresented {
                stopping = nil
            }
        }
    }

    var onBinding: Binding<Bool> {
        Binding {
            model.output.shownOn
        } set: { isOn in
            guard !isOn || isPro else {
                proOffer = .sync
                return
            }

            turn(isOn)
        }
    }

    static func hasFinishedSyncing(
        from old: SyncProgress?,
        to new: SyncProgress?
    ) -> Bool {
        guard
            old?.isBusy == true,
            case .upToDate = new
        else {
            return false
        }

        return true
    }

    func turn(_ isOn: Bool) {
        guard model.request(isOn) else {
            return
        }

        model.perform {
            await $0.setOn(isOn)
        }
    }

    func unlock() {
        guard let offer = proOffer else {
            return
        }

        proOffer = nil

        switch offer {
        case .sync:
            turn(true)

        case let .share(item):
            model.perform {
                await $0.open(item)
            }
        }
    }

    func leave(_ item: JoinedShare?) {
        guard let item else {
            return
        }

        model.perform {
            await $0.leave(item)
        }
    }

    func askToStop(_ item: WalletShare) {
        model.closeOpened()
        stopping = item
    }

    func stopSharing(_ item: WalletShare?) {
        guard let item else {
            return
        }

        model.perform {
            await $0.stopSharing(item)
        }
    }

    func confirmInvitation() {
        model.perform {
            await $0.confirmInvitation()
        }
    }

    func inviteMore() {
        model.perform {
            await $0.inviteMore()
        }
    }

    func useLocalData() {
        model.perform {
            await $0.useLocalData()
        }
    }

    func useCloudData() {
        model.perform {
            await $0.useCloudData()
        }
    }
}

private extension SyncView {
    var hint: SettingsFold {
        SettingsFold(\.hint, in: model)
    }
}

#Preview {
    if let parts = ScreenParts.preview() {
        NavigationStack {
            SyncView(
                model: SyncModel(
                    parts: parts,
                    cloud: .unavailable
                )
            )
        }
    }
}
