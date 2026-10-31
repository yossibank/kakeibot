import DesignSystem
import Store
import SwiftUI

extension SyncView {
    var sharingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle("共有する口座")
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
            .disabled(isSharingLocked)

            SettingsCaption("同期のオン・オフに関係なく、口座ごとに共有できます。")

            steps
        }
    }

    var joinedSection: some View {
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
            .disabled(isSharingLocked)

            SettingsCaption("抜けると、この iPhone からその口座と記録が消えます。", kind: .caution)
        }
    }
}

private extension SyncView {
    var steps: some View {
        VStack(alignment: .leading, spacing: 8) {
            step(1, "「招待」から、相手に招待を送ります")

            step(2, "相手が、届いたリンクを開きます")

            step(3, "相手のかけいぼっとにこの口座が並び、一緒に記録できます")
        }
        .padding(.top, 8)
        .padding(.leading, 8)
    }

    func step(
        _ number: Int,
        _ text: String
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("\(number)")
                .textFont(.caption2, weight: .bold)
                .foregroundStyle(Palette.accent)
                .frame(width: 20, height: 20)
                .overlay {
                    Circle()
                        .stroke(Palette.outline, lineWidth: 0.8)
                }

            Text(text)
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    func shareRow(_ item: WalletShare) -> some View {
        HStack(spacing: 12) {
            IconBadge(item.icon, size: 32)

            Text(item.wallet.name)
                .textFont(.subheadline)
                .foregroundStyle(Palette.text)
                .sharedTextScale()

            Spacer(minLength: 0)

            Button {
                guard item.isShared || isPro else {
                    proOffer = .share(item)
                    return
                }

                Task {
                    await model.open(item)
                }
            } label: {
                shareLabel(
                    isShared: item.isShared,
                    isWorking: model.workingWallet == item.wallet.id
                )
            }
            .buttonStyle(.plain)
        }
        .frame(minHeight: 58)
    }

    func shareLabel(
        isShared: Bool,
        isWorking: Bool
    ) -> some View {
        Group {
            if isShared {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")

                    Text("共有中")

                    Image(systemName: "chevron.right")
                        .textFont(.caption2, weight: .bold)
                }
                .textFont(.footnote, weight: .bold)
                .foregroundStyle(Palette.subtext)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "person.badge.plus")

                    Text("招待")
                }
                .textFont(.footnote, weight: .bold)
                .padding(.horizontal, 16)
                .frame(minHeight: 32)
                .goldFace()
            }
        }
        .opacity(isWorking ? 0 : 1)
        .overlay {
            if isWorking {
                ProgressView()
                    .controlSize(.small)
                    .tint(isShared ? Palette.subtext : Palette.accent)
            }
        }
        .frame(minHeight: 32)
        .contentShape(Rectangle())
        .fixedSize()
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
                pill(
                    "抜ける",
                    systemImage: nil,
                    color: Palette.rose,
                    isFilled: false,
                    isWorking: model.workingWallet == item.wallet.id
                )
            }
            .buttonStyle(.plain)
        }
        .frame(minHeight: 58)
    }

    func pill(
        _ title: String,
        systemImage: String?,
        color: Color,
        isFilled: Bool,
        isWorking: Bool
    ) -> some View {
        let fill = isFilled ? color.opacity(.muted) : .clear

        return HStack(spacing: 4) {
            Text(title)

            if let systemImage {
                Image(systemName: systemImage)
                    .textFont(.caption2, weight: .bold)
            }
        }
        .textFont(.footnote, weight: .bold)
        .foregroundStyle(color)
        .opacity(isWorking ? 0 : 1)
        .overlay {
            if isWorking {
                ProgressView()
                    .controlSize(.small)
                    .tint(color)
            }
        }
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
    var isSharingLocked: Bool {
        model.isWorking || model.workingWallet != nil || !model.isAvailable
    }
}
