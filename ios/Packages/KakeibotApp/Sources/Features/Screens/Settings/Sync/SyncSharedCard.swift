import Core
import DesignSystem
import Store
import SwiftUI

struct SyncSharedCard: View {
    let item: WalletShare
    let participants: [SyncParticipant]?
    let isFailed: Bool
    let onInvite: () -> Void
    let onStop: () -> Void
    let onClose: () -> Void

    var body: some View {
        ModalCard(maxWidth: 360, onDismiss: onClose) {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    IconBadge(item.icon, size: 52)

                    Text(item.wallet.name)
                        .textFont(.subheadline, weight: .bold)
                        .foregroundStyle(Palette.subtext)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    Text("ほかの人と共有しています")
                        .displayFont(.headline, weight: .medium)
                        .foregroundStyle(Palette.accentStrong)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("参加している人")
                        .textFont(.caption, weight: .bold)
                        .foregroundStyle(Palette.subtext)

                    members
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .background(Palette.faint, in: .rect(cornerRadius: 16))
                }

                Text("招待した人は、リンクを開くと参加中になります")
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 12) {
                    CardButton("ほかの人も誘う", style: .filled, action: onInvite)
                    CardButton("共有をやめる", style: .outlined(Palette.rose), action: onStop)
                    CardButton("閉じる", style: .outlined(Palette.subtext), action: onClose)
                }
            }
        }
    }
}

private extension SyncSharedCard {
    @ViewBuilder
    var members: some View {
        if let participants {
            VStack(spacing: 0) {
                ForEach(Array(participants.enumerated()), id: \.offset) { index, participant in
                    if index > 0 {
                        Hairline()
                    }

                    member(participant)
                }
            }
        } else if isFailed {
            Text("参加している人を読み込めませんでした")
                .textFont(.footnote)
                .foregroundStyle(Palette.rose)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 12)
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 48)
        }
    }

    func member(_ participant: SyncParticipant) -> some View {
        let isInvited = participant.state == .invited
        let color = isInvited ? Palette.subtext : Palette.accent

        return HStack(spacing: 8) {
            Image(systemName: "person.crop.circle")
                .foregroundStyle(Palette.subtext)

            Text(name(of: participant))
                .textFont(.subheadline)
                .foregroundStyle(Palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)

            Text(stateText(of: participant))
                .textFont(.caption2, weight: .bold)
                .foregroundStyle(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .overlay {
                    Capsule()
                        .stroke(color.opacity(.medium), lineWidth: 1)
                }
                .fixedSize()
        }
        .frame(minHeight: 44)
    }
}

private extension SyncSharedCard {
    func name(of participant: SyncParticipant) -> String {
        guard participant.name.isEmpty else {
            return participant.name
        }

        return participant.state == .owner ? "自分" : "名前の無い人"
    }

    func stateText(of participant: SyncParticipant) -> String {
        switch participant.state {
        case .owner: "自分"
        case .joined: "参加中"
        case .invited: "招待中"
        }
    }
}

#Preview {
    SyncSharedCard(
        item: WalletShare(
            wallet: Wallet(
                name: "家計の口座",
                kind: .cash,
                iconId: Icon.ID(),
                initialBalance: 0,
                sortOrder: 0,
                createdAt: Date(),
                updatedAt: Date()
            ),
            icon: nil,
            isShared: true
        ),
        participants: [
            SyncParticipant(name: "山田 太郎", state: .owner),
            SyncParticipant(name: "山田 花子", state: .joined),
            SyncParticipant(name: "taro@example.com", state: .invited)
        ],
        isFailed: false,
        onInvite: {},
        onStop: {},
        onClose: {}
    )
    .background(Palette.background)
}
