import Core
import DesignSystem
import FeatureModels
import SwiftUI

public struct SyncView: View {
    @State var model: SyncModel

    @Environment(\.isPro) var isPro

    @Environment(\.scenePhase) private var scenePhase

    public init(model: SyncModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        let presented = model.state.presented.dialog.current

        content
            .confirmation(
                isPresented: isPresenting(presented?.leaving.map { .leave($0) }),
                systemImage: "person.crop.circle.badge.minus",
                title: "共有から抜けますか",
                message: "この \(DeviceName.current) から口座と記録が消えます。自分の口座との振替は、支出と収入にして残します",
                keepTitle: "やめる",
                confirmTitle: "抜ける"
            ) {
                leave(presented?.leaving)
            }
            .confirmation(
                isPresented: isPresenting(presented?.stopping.map { .stop($0) }),
                systemImage: "person.2.slash",
                title: "共有を終えますか",
                message: "相手の端末から、この口座と記録が消えます。この \(DeviceName.current) には残ります",
                keepTitle: "やめる",
                confirmTitle: "共有を終える"
            ) {
                stopSharing(presented?.stopping)
            }
            .overlay {
                cardOverlay
            }
            .animation(.snappy(duration: 0.25), value: model.output.choice)
            .animation(.snappy(duration: 0.25), value: model.output.invitation)
            .animation(.snappy(duration: 0.25), value: model.output.opened)
            .proOffer(presented?.offer?.feature) {
                close(presented)
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

private extension SyncView {
    var content: some View {
        VStack(spacing: 16) {
            SettingsBackHeader("同期と共有", hint: hint)

            SyncIntroCard(hint: hint)

            sections
        }
        .padding(.horizontal, SettingsSpacing.side)
        .padding(.top, SettingsSpacing.top)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .errorBanner(model.state.notices.error)
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
    }

    var sections: some View {
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
                        .disabled(isSwitchLocked)

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

    @ViewBuilder
    var cardOverlay: some View {
        if let choice = model.output.choice {
            SyncChoiceCard(
                choice: choice,
                onUseLocal: useLocalData,
                onUseCloud: useCloudData,
                onKeep: model.cancelChoice
            )
        } else if let invitation = model.output.invitation {
            SyncInviteCard(
                item: invitation,
                onInvite: confirmInvitation,
                onCancel: model.cancelInvitation
            )
        } else if let opened = model.output.opened {
            SyncSharedCard(
                item: opened,
                participants: model.output.participants,
                isFailed: model.output.isParticipantsFailed,
                onInvite: inviteMore,
                onStop: {
                    model.askToStop(opened)
                },
                onClose: model.closeOpened
            )
        }
    }

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

    var isSwitchLocked: Bool {
        let isRunning = model.state.task.isRunning(SyncModel.Work.switching)
        return isRunning || model.output.isSwitching || !canChange
    }

    var onBinding: Binding<Bool> {
        Binding {
            model.output.shownOn
        } set: { isOn in
            guard !isOn || isPro else {
                model.state.presented.dialog.show(.offer(.sync))
                return
            }

            turn(isOn)
        }
    }

    var hint: SettingsFold {
        SettingsFold(\.hint, in: model)
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

    func isPresenting(_ presented: SyncModel.Dialog?) -> Binding<Bool> {
        Binding {
            presented != nil
        } set: { isPresented in
            if !isPresented {
                close(presented)
            }
        }
    }

    func close(_ presented: SyncModel.Dialog?) {
        if let presented {
            model.state.presented.dialog.close(presented)
        }
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
        guard let offer = model.state.presented.dialog.current?.offer else {
            return
        }

        model.state.presented.dialog.close(.offer(offer))

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
