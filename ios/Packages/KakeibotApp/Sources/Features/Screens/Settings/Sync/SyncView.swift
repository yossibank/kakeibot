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
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        note("arrow.triangle.2.circlepath", "記録と設定を、同じ iCloud の端末どうしでそろえます")

                        note("lock", "データは iCloud に暗号化して置きます")
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Text("同期する")
                                .textFont(.subheadline)
                                .foregroundStyle(Palette.text)

                            Spacer(minLength: 0)

                            CapsulePicker(selection: onBinding, options: Self.onOptions)
                        }
                        .frame(minHeight: 58)
                        .padding(.horizontal, 16)
                        .card()
                        .disabled(model.isWorking || !canChange)

                        if !model.isOn,
                           let reason = model.stopReason {
                            warning(reason.message)
                        }

                        if model.isOn,
                           let count = model.pendingCount {
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
                                .padding(.leading, 8)
                            }
                        }

                        Text(model.footnote)
                            .textFont(.footnote)
                            .foregroundStyle(Palette.subtext)
                            .padding(.leading, 8)
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

                                    Button {
                                        Task {
                                            await model.share(item)
                                        }
                                    } label: {
                                        shareRow(item)
                                    }
                                }
                            }
                            .sharesTextScale(id: model.shares.map(\.wallet.name))
                            .buttonStyle(.plain)
                            .padding(.horizontal, 16)
                            .card()
                            .disabled(model.isWorking || !model.isAvailable)

                            Text("口座ごとに、家族と記録を分けあえます")
                                .textFont(.footnote)
                                .foregroundStyle(Palette.subtext)
                                .padding(.leading, 8)
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

                                    Button {
                                        leaving = item
                                    } label: {
                                        joinedRow(item)
                                    }
                                }
                            }
                            .sharesTextScale(id: model.joined.map(\.wallet.name))
                            .buttonStyle(.plain)
                            .padding(.horizontal, 16)
                            .card()
                            .disabled(model.isWorking || !model.isAvailable)

                            Text("抜けると、この iPhone からその口座と記録が消えます")
                                .textFont(.footnote)
                                .foregroundStyle(Palette.subtext)
                                .padding(.leading, 8)
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
            Rectangle()
                .fill(Palette.background)
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
        .confirmation(
            isPresented: $model.isChoosing,
            systemImage: "icloud",
            title: "iCloud にもデータがあります",
            message: SyncModel.choiceMessage,
            keepTitle: "やめる",
            confirmTitle: "iCloud のデータを使う",
            alternateTitle: "この iPhone のデータを使う",
            role: .suggestion,
            onAlternate: {
                Task {
                    await model.useLocalData()
                }
            }
        ) {
            Task {
                await model.useCloudData()
            }
        }
    }
}

private extension SyncView {
    func note(
        _ systemImage: String,
        _ text: String
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: systemImage)
                .sansFont(.caption, weight: .medium)
                .foregroundStyle(Palette.accent)
                .frame(width: 22)

            Text(text)
                .textFont(.footnote)
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)
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
        .padding(.leading, 8)
    }

    func joinedRow(_ item: JoinedShare) -> some View {
        HStack(spacing: 12) {
            IconBadge(item.icon, size: 32)

            Text(item.wallet.name)
                .textFont(.subheadline)
                .foregroundStyle(Palette.text)
                .sharedTextScale()

            Spacer(minLength: 0)

            Text("抜ける")
                .textFont(.footnote)
                .foregroundStyle(Palette.rose)
        }
        .frame(minHeight: 58)
        .contentShape(.rect)
    }

    func shareRow(_ item: WalletShare) -> some View {
        HStack(spacing: 12) {
            IconBadge(item.icon, size: 32)

            Text(item.wallet.name)
                .textFont(.subheadline)
                .foregroundStyle(Palette.text)
                .sharedTextScale()

            Spacer(minLength: 0)

            Text(shareStatus(item))
                .textFont(.footnote)
                .foregroundStyle(shareTint(item))

            Image(systemName: "chevron.right")
                .sansFont(.small)
                .foregroundStyle(Palette.hint)
        }
        .frame(minHeight: 58)
        .contentShape(.rect)
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

    var onBinding: Binding<Bool> {
        Binding {
            model.isOn
        } set: { isOn in
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

    func shareStatus(_ item: WalletShare) -> String {
        item.isShared ? "共有中" : "共有する"
    }

    func shareTint(_ item: WalletShare) -> Color {
        item.isShared ? Palette.subtext : Palette.accent
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
