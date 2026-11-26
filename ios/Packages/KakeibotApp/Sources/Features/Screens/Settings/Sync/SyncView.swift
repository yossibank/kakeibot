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
        let asking = model.state.asking

        content
            .confirmation(
                isPresented: isAsking(asking?.leaving.map { .leave($0) }),
                systemImage: "person.crop.circle.badge.minus",
                title: "共有から抜けますか",
                message: "この \(DeviceName.current) から口座と記録が消えます。自分の口座との振替は、支出と収入にして残します",
                keepTitle: "やめる",
                confirmTitle: "抜ける"
            ) {
                leave(asking?.leaving)
            }
            .confirmation(
                isPresented: isAsking(asking?.stopping.map { .stop($0) }),
                systemImage: "person.2.slash",
                title: "共有を終えますか",
                message: "相手の端末から、この口座と記録が消えます。この \(DeviceName.current) には残ります",
                keepTitle: "やめる",
                confirmTitle: "共有を終える"
            ) {
                stopSharing(asking?.stopping)
            }
            .overlay {
                cardOverlay
            }
            .animation(.snappy(duration: 0.25), value: model.state.choice)
            .animation(.snappy(duration: 0.25), value: model.state.invitation)
            .animation(.snappy(duration: 0.25), value: model.state.opened)
            .proOffer(asking?.offer?.feature) {
                model.state.close(asking)
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

    @ViewBuilder
    var cardOverlay: some View {
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

    var onBinding: Binding<Bool> {
        Binding {
            model.output.shownOn
        } set: { isOn in
            guard !isOn || isPro else {
                model.state.ask(.offer(.sync))
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

    func isAsking(_ asking: SyncModel.Asking?) -> Binding<Bool> {
        Binding {
            asking != nil
        } set: { isPresented in
            if !isPresented {
                model.state.close(asking)
            }
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
        guard let offer = model.state.asking?.offer else {
            return
        }

        model.state.close(.offer(offer))

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
