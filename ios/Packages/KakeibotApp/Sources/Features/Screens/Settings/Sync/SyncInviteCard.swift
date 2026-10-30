import Core
import DesignSystem
import Store
import SwiftUI

struct SyncInviteCard: View {
    let item: WalletShare
    let onInvite: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ModalCard(maxWidth: 360, onDismiss: onCancel) {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Image(systemName: "person.2")
                        .sansFont(.headline, weight: .ultraLight)
                        .foregroundStyle(Palette.accent)
                        .frame(width: 52, height: 52)
                        .overlay {
                            Circle()
                                .stroke(Palette.outline, lineWidth: 0.8)
                        }

                    Text(item.wallet.name)
                        .textFont(.subheadline, weight: .bold)
                        .foregroundStyle(Palette.subtext)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    Text("この口座を\n家族と共有します")
                        .displayFont(.headline, weight: .medium)
                        .foregroundStyle(Palette.accentStrong)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 16) {
                    point(
                        "tray.full",
                        title: "共有するもの",
                        text: "この口座と、その記録・カテゴリ。2 人で付けて直せます"
                    )

                    point(
                        "person.crop.circle.badge.checkmark",
                        title: "家族に要るもの",
                        text: "かけいぼっとと iCloud のサインイン。届いたリンクを開きます"
                    )

                    point(
                        "hand.raised",
                        title: "やめるとき",
                        text: "この画面でいつでもやめられます。家族の iPhone からは消えます"
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("次の画面で、メッセージなどから招待を送ります")
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 12) {
                    CardButton("招待を送る", style: .filled, action: onInvite)

                    CardButton("あとで", style: .outlined(Palette.subtext), action: onCancel)
                }
            }
        }
    }
}

private extension SyncInviteCard {
    func point(
        _ systemImage: String,
        title: String,
        text: String
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: systemImage)
                .sansFont(.caption, weight: .medium)
                .foregroundStyle(Palette.accent)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .textFont(.caption, weight: .bold)
                    .foregroundStyle(Palette.text)

                Text(text)
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    SyncInviteCard(
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
            isShared: false
        ),
        onInvite: {},
        onCancel: {}
    )
    .background(Palette.background)
}
