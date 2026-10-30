import DesignSystem
import Store
import SwiftUI

public struct SyncView: View {
    @State var model: SyncModel
    @State var leaving: JoinedShare?
    @State var stopping: WalletShare?

    @Environment(\.scenePhase) private var scenePhase

    public init(model: SyncModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        VStack(spacing: 16) {
            SettingsBackHeader("iCloud 同期")

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    SyncIntroCard()

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
                            .disabled(model.isWorking || model.isSwitching || !canChange)

                            if let progress = model.progress {
                                Hairline()

                                status(progress)
                                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            }
                        }
                        .padding(.horizontal, 16)
                        .card()

                        caption(model.footnote)
                    }

                    if !model.shares.isEmpty {
                        sharingSection
                    }

                    if !model.joined.isEmpty {
                        joinedSection
                    }
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .background {
            Backdrop()
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task {
                    await model.refreshAccount()
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
            message: "この iPhone から口座と記録が消えます。自分の口座との振替は、支出と収入にして残します",
            keepTitle: "やめる",
            confirmTitle: "抜ける"
        ) {
            leave()
        }
        .confirmation(
            isPresented: isStoppingBinding,
            systemImage: "person.2.slash",
            title: "共有をやめますか",
            message: "家族の iPhone から、この口座と記録が消えます。この iPhone には残ります",
            keepTitle: "続ける",
            confirmTitle: "やめる"
        ) {
            stopSharing()
        }
        .overlay {
            if let choice = model.choice {
                SyncChoiceCard(
                    choice: choice,
                    onUseLocal: useLocalData,
                    onUseCloud: useCloudData,
                    onKeep: model.cancelChoice
                )
            } else if let invitation = model.invitation {
                SyncInviteCard(
                    item: invitation,
                    onInvite: confirmInvitation,
                    onCancel: model.cancelInvitation
                )
            } else if let opened = model.opened {
                SyncSharedCard(
                    item: opened,
                    participants: model.participants,
                    isFailed: model.isParticipantsFailed,
                    onInvite: inviteMore,
                    onStop: {
                        askToStop(opened)
                    },
                    onClose: model.closeOpened
                )
            }
        }
        .animation(.snappy(duration: 0.25), value: model.choice)
        .animation(.snappy(duration: 0.25), value: model.invitation)
        .animation(.snappy(duration: 0.25), value: model.opened)
        .haptic(.selection, trigger: model.isChoosing) { _, new in
            new
        }
        .haptic(.success, trigger: model.progress) { old, new in
            Self.hasFinishedSyncing(from: old, to: new)
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

extension SyncView {
    func caption(_ text: String) -> some View {
        Text(text)
            .textFont(.caption)
            .foregroundStyle(Palette.subtext)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.leading, 8)
    }
}

private extension SyncView {
    static let onOptions: [CapsulePicker<Bool>.Option] = [
        .init("オフ", value: false),
        .init("オン", value: true)
    ]

    var canChange: Bool {
        model.isOn || model.isAvailable
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
            model.shownOn
        } set: { isOn in
            guard model.request(isOn) else {
                return
            }

            Task {
                await model.setOn(isOn)
            }
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

    func leave() {
        guard let leaving else {
            return
        }

        self.leaving = nil

        Task {
            await model.leave(leaving)
        }
    }

    func askToStop(_ item: WalletShare) {
        model.closeOpened()
        stopping = item
    }

    func stopSharing() {
        guard let stopping else {
            return
        }

        self.stopping = nil

        Task {
            await model.stopSharing(stopping)
        }
    }

    func confirmInvitation() {
        Task {
            await model.confirmInvitation()
        }
    }

    func inviteMore() {
        Task {
            await model.inviteMore()
        }
    }

    func useLocalData() {
        Task {
            await model.useLocalData()
        }
    }

    func useCloudData() {
        Task {
            await model.useCloudData()
        }
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        NavigationStack {
            SyncView(
                model: SyncModel(
                    database: database,
                    cloud: .unavailable
                )
            )
        }
    }
}
