import DesignSystem
import Store
import SwiftUI

public struct SyncView: View {
    @State private var model: SyncModel
    @State private var leaving: JoinedShare?

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

                            if hasStatus {
                                Hairline()

                                status
                                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            }
                        }
                        .padding(.horizontal, 16)
                        .card()

                        caption(model.footnote)
                    }

                    if !model.shares.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionTitle("家族と共有する口座")
                                .padding(.leading, 8)

                            VStack(spacing: 0) {
                                ForEach(model.shares, id: \.wallet.id) { item in
                                    if item.wallet.id != model.shares.first?.wallet.id {
                                        Hairline()
                                    }

                                    shareRow(item)
                                }
                            }
                            .sharesTextScale(id: model.shares.map(\.wallet.name))
                            .padding(.horizontal, 16)
                            .card()
                            .disabled(model.isWorking || !model.isAvailable)

                            caption("口座ごとに、家族と記録を分けあえます")
                        }
                    }

                    if !model.joined.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionTitle("誘われた口座")
                                .padding(.leading, 8)

                            VStack(spacing: 0) {
                                ForEach(model.joined, id: \.wallet.id) { item in
                                    if item.wallet.id != model.joined.first?.wallet.id {
                                        Hairline()
                                    }

                                    joinedRow(item)
                                }
                            }
                            .sharesTextScale(id: model.joined.map(\.wallet.name))
                            .padding(.horizontal, 16)
                            .card()
                            .disabled(model.isWorking || !model.isAvailable)

                            caption("抜けると、この iPhone からその口座と記録が消えます")
                        }
                    }

                    if model.isWorking {
                        ProgressView()
                            .frame(maxWidth: .infinity)
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
            await model.observeStatus()
        }
        .task {
            await model.observePending()
        }
        .task {
            await model.observeShares()
        }
        .task {
            await model.observeJoined()
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
        .overlay {
            if let choice = model.choice {
                SyncChoiceCard(
                    choice: choice,
                    onUseLocal: useLocalData,
                    onUseCloud: useCloudData,
                    onKeep: model.cancelChoice
                )
            }
        }
        .animation(.snappy(duration: 0.25), value: model.choice)
        .haptic(.selection, trigger: model.isChoosing) { _, new in
            new
        }
    }
}

private extension SyncView {
    @ViewBuilder
    var status: some View {
        if !model.isOn,
           let reason = model.stopReason {
            warning(reason.message)
        } else if let count = model.pendingCount {
            if count > 0,
               model.sendProblem != nil {
                warning(model.pendingText(count))
            } else {
                HStack(spacing: 8) {
                    if count > 0 {
                        ProgressView()
                            .controlSize(.mini)
                    } else {
                        Image(systemName: "checkmark.circle")
                            .foregroundStyle(Palette.accent)
                    }

                    Text(model.pendingText(count))
                }
                .textFont(.footnote)
                .foregroundStyle(Palette.subtext)
            }
        }
    }

    func caption(_ text: String) -> some View {
        Text(text)
            .textFont(.caption)
            .foregroundStyle(Palette.subtext)
            .padding(.leading, 8)
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

    func joinedRow(_ item: JoinedShare) -> some View {
        HStack(spacing: 12) {
            IconBadge(item.icon, size: 32)

            Text(item.wallet.name)
                .textFont(.subheadline)
                .foregroundStyle(Palette.text)
                .sharedTextScale()

            Spacer(minLength: 0)

            Button {
                leaving = item
            } label: {
                pill("抜ける", color: Palette.rose, isFilled: false)
            }
            .buttonStyle(.plain)
        }
        .frame(minHeight: 58)
    }

    func shareRow(_ item: WalletShare) -> some View {
        let title = item.isShared ? "共有中" : "共有する"

        return HStack(spacing: 12) {
            IconBadge(item.icon, size: 32)

            Text(item.wallet.name)
                .textFont(.subheadline)
                .foregroundStyle(Palette.text)
                .sharedTextScale()

            Spacer(minLength: 0)

            Button {
                Task {
                    await model.share(item)
                }
            } label: {
                pill(title, color: Palette.accent, isFilled: !item.isShared)
            }
            .buttonStyle(.plain)
        }
        .frame(minHeight: 58)
    }

    func pill(
        _ title: String,
        color: Color,
        isFilled: Bool
    ) -> some View {
        let fill = isFilled ? color.opacity(.muted) : .clear

        return Text(title)
            .textFont(.footnote, weight: .bold)
            .foregroundStyle(color)
            .padding(.horizontal, 16)
            .frame(minHeight: 32)
            .background(fill, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(color.opacity(.medium), lineWidth: 1)
            }
            .contentShape(Capsule())
            .fixedSize()
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

    var hasStatus: Bool {
        let isStopped = !model.isOn && model.stopReason != nil
        let isSending = model.isOn && model.pendingCount != nil

        return isStopped || isSending
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

    func leave() {
        guard let leaving else {
            return
        }

        self.leaving = nil

        Task {
            await model.leave(leaving)
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
