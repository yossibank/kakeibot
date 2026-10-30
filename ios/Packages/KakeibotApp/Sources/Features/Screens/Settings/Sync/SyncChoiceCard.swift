import DesignSystem
import Store
import SwiftUI

struct SyncChoiceCard: View {
    let choice: SyncChoice
    let onUseLocal: () -> Void
    let onUseCloud: () -> Void
    let onKeep: () -> Void

    var body: some View {
        ModalCard(maxWidth: 360, onDismiss: onKeep) {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Image(systemName: "icloud")
                        .sansFont(.headline, weight: .ultraLight)
                        .foregroundStyle(Palette.accent)
                        .frame(width: 52, height: 52)
                        .overlay {
                            Circle()
                                .stroke(Palette.outline, lineWidth: 0.8)
                        }

                    Text("iCloud にも\nデータがあります")
                        .displayFont(.headline, weight: .medium)
                        .foregroundStyle(Palette.accentStrong)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("使う方を選んでください。\n選ばなかった方は置き換わります")
                        .textFont(.caption)
                        .foregroundStyle(Palette.subtext)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(alignment: .top, spacing: 12) {
                    tile(.local)

                    tile(.cloud)
                }

                Text("「この iPhone」を選ぶと、\nほかの端末の同期は切れます")
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                CardButton("やめる", style: .outlined(Palette.subtext), action: onKeep)
            }
        }
    }
}

private extension SyncChoiceCard {
    func tile(_ side: SyncChoice.Side) -> some View {
        let summary = summary(of: side)
        let isNewer = choice.newer == side
        let buttonStyle: CardButton.Style = isNewer ? .filled : .outlined(Palette.accent)
        let rim = isNewer ? Palette.accent : Palette.hairline

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: symbol(of: side))

                Text(name(of: side))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .textFont(.caption, weight: .bold)
            .foregroundStyle(Palette.accentStrong)

            VStack(alignment: .leading, spacing: 4) {
                Text("記録 \(summary.entryCount.formatted()) 件")
                    .textFont(.subheadline, weight: .bold)
                    .foregroundStyle(Palette.text)

                Text("最後の更新")
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)

                Text(updatedText(summary))
                    .textFont(.footnote)
                    .foregroundStyle(Palette.text)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)

            CardButton("使う", style: buttonStyle, height: 40) {
                use(side)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.faint, in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(rim, lineWidth: 1)
        }
        .overlay(alignment: .top) {
            if isNewer {
                Text("新しい")
                    .textFont(.caption2, weight: .bold)
                    .foregroundStyle(Palette.backgroundBottom)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Palette.accent, in: Capsule())
                    .fixedSize()
                    .offset(y: -9)
            }
        }
    }
}

private extension SyncChoiceCard {
    func summary(of side: SyncChoice.Side) -> SyncSummary {
        switch side {
        case .local: choice.local
        case .cloud: choice.cloud
        }
    }

    func name(of side: SyncChoice.Side) -> String {
        switch side {
        case .local: "この iPhone"
        case .cloud: "iCloud"
        }
    }

    func symbol(of side: SyncChoice.Side) -> String {
        switch side {
        case .local: "iphone"
        case .cloud: "icloud"
        }
    }

    func updatedText(_ summary: SyncSummary) -> String {
        guard let updatedAt = summary.updatedAt else {
            return "なし"
        }

        return updatedAt.formatted(.dateTime.month(.defaultDigits).day().hour().minute())
    }
}

private extension SyncChoiceCard {
    func use(_ side: SyncChoice.Side) {
        switch side {
        case .local: onUseLocal()
        case .cloud: onUseCloud()
        }
    }
}

#Preview {
    SyncChoiceCard(
        choice: SyncChoice(
            local: SyncSummary(
                entryCount: 1234,
                updatedAt: Date(timeIntervalSince1970: 1_793_221_440)
            ),
            cloud: SyncSummary(
                entryCount: 1301,
                updatedAt: Date(timeIntervalSince1970: 1_793_349_120)
            )
        ),
        onUseLocal: {},
        onUseCloud: {},
        onKeep: {}
    )
    .background(Palette.background)
}
