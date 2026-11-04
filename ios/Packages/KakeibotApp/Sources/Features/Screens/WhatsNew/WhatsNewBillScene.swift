import Core
import DesignSystem
import SwiftUI

struct WhatsNewBillScene: View {
    let kind: WhatsNewScene.Kind

    var body: some View {
        switch kind {
        case .unpaidButton:
            unpaidButton
                .whatsNewTapped()

        case .unpaidList:
            unpaidList

        case .shiftWallet:
            shiftWallet

        case .shiftChoice:
            shiftChoice
                .whatsNewTapped()

        case .shiftBill:
            shiftBill

        default:
            unpaidRow
        }
    }
}

private extension WhatsNewBillScene {
    struct UnpaidEntry {
        let name: String
        let amount: Int
    }

    static let shiftTitles = ["いつもどおり", "次に回す", "2 回先"]

    static let unpaidEntries = [
        UnpaidEntry(name: "スーパー", amount: 3280),
        UnpaidEntry(name: "ドラッグストア", amount: 1460),
        UnpaidEntry(name: "本屋", amount: 1760)
    ]

    static var unpaidTotal: Int {
        unpaidEntries.map(\.amount).reduce(0, +)
    }

    var unpaidRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "creditcard")
                    .foregroundStyle(Palette.accent)

                Text("カード")
                    .foregroundStyle(Palette.text)

                Spacer(minLength: 4)

                Text(AmountText.text(Self.unpaidTotal))
                    .monospacedDigit()
                    .foregroundStyle(Palette.text)
            }
            .textFont(size: .caption, weight: .semibold)

            Text("11/27 引き落とし")
                .textFont(size: .micro)
                .monospacedDigit()
                .foregroundStyle(Palette.subtext)
                .padding(.horizontal, 8)
                .frame(height: 20)
                .background(Palette.faint, in: .capsule)
        }
        .padding(12)
        .card(cornerRadius: 12)
        .padding(.horizontal, 4)
    }

    var unpaidButton: some View {
        Label("未払いの記録を見る", systemImage: "list.bullet")
            .textFont(size: .caption, weight: .semibold)
            .foregroundStyle(Palette.accent)
            .padding(.horizontal, 12)
            .frame(height: 30)
            .overlay {
                Capsule()
                    .stroke(Palette.accent.opacity(.muted), lineWidth: 1)
            }
    }

    var unpaidList: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("11/27 に引き落とし")
                .textFont(size: .micro)
                .foregroundStyle(Palette.subtext)

            Text(AmountText.text(Self.unpaidTotal))
                .displayFont(.headline, weight: .bold)
                .foregroundStyle(Palette.accentStrong)

            ForEach(Self.unpaidEntries, id: \.name) { entry in
                HStack {
                    Text(entry.name)
                        .foregroundStyle(Palette.text)

                    Spacer(minLength: 4)

                    Text(AmountText.text(entry.amount))
                        .foregroundStyle(Palette.subtext)
                }
                .textFont(size: .caption)
            }
        }
        .monospacedDigit()
        .padding(.horizontal, 12)
    }

    var shiftWallet: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("支払い元")
                .textFont(size: .micro, weight: .semibold)
                .tracking(1)
                .foregroundStyle(Palette.accent)

            HStack(spacing: 4) {
                ForEach(["財布", "カード"], id: \.self) { name in
                    choice(name, isSelected: name == "カード", height: 28)
                }
            }
        }
        .padding(12)
        .card(cornerRadius: 12)
        .padding(.horizontal, 4)
    }

    var shiftChoice: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("請求")
                .textFont(size: .micro, weight: .semibold)
                .foregroundStyle(Palette.accent)

            ForEach(Self.shiftTitles, id: \.self) { title in
                choice(title, isSelected: title == "次に回す", height: 24)
            }
        }
        .padding(.horizontal, 12)
    }

    var shiftBill: some View {
        VStack(spacing: 4) {
            Text("引き落とし")
                .textFont(size: .caption)
                .foregroundStyle(Palette.subtext)

            HStack(spacing: 4) {
                Text("11/27")
                    .strikethrough()
                    .foregroundStyle(Palette.hint)

                Image(systemName: "arrow.right")
                    .foregroundStyle(Palette.hint)

                Text("12/27")
                    .bold()
                    .foregroundStyle(Palette.accentStrong)
            }
            .textFont(size: .caption)

            Text("12月の請求に入る")
                .textFont(size: .caption, weight: .semibold)
                .foregroundStyle(Palette.accentStrong)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Palette.accent.opacity(.subtle), in: .capsule)
        }
        .monospacedDigit()
    }

    func choice(
        _ title: String,
        isSelected: Bool,
        height: CGFloat
    ) -> some View {
        Text(title)
            .textFont(size: .caption, weight: isSelected ? .semibold : .regular)
            .foregroundStyle(isSelected ? Palette.accentStrong : Palette.subtext)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(SettingsTile.fill(isSelected: isSelected), in: .capsule)
            .overlay {
                Capsule()
                    .stroke(SettingsTile.stroke(isSelected: isSelected), lineWidth: 1)
            }
    }
}
