import Core
import DesignSystem
import FeatureModels
import SwiftUI

struct WhatsNewMonthStartScene: View {
    let step: Step

    var body: some View {
        switch step {
        case .day:
            day

        case .shift:
            shift
                .whatsNewTapped()

        case .period:
            period
        }
    }
}

extension WhatsNewMonthStartScene {
    enum Step: Hashable, Sendable {
        case day
        case shift
        case period
    }
}

private extension WhatsNewMonthStartScene {
    var day: some View {
        VStack(spacing: 8) {
            Text("月の始まり")
                .textFont(size: .micro, weight: .semibold)
                .tracking(1)
                .foregroundStyle(Palette.accent)

            HStack(spacing: 4) {
                ForEach(23...27, id: \.self) { day in
                    let isSelected = day == 25

                    Text("\(day)")
                        .textFont(size: .caption, weight: isSelected ? .bold : .regular)
                        .monospacedDigit()
                        .foregroundStyle(isSelected ? Palette.backgroundTop : Palette.text)
                        .frame(width: 22, height: 22)
                        .background(isSelected ? Palette.accent : .clear, in: Circle())
                }
            }

            Text("毎月 25 日")
                .textFont(size: .caption)
                .foregroundStyle(Palette.subtext)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .card(cornerRadius: 12)
        .padding(.horizontal, 4)
    }

    var shift: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("土日・祝日のとき")
                .textFont(size: .micro, weight: .semibold)
                .foregroundStyle(Palette.accent)

            ForEach(HolidayShift.allCases, id: \.self) { shift in
                let isSelected = shift == .previous

                Text(shift.title)
                    .textFont(size: .caption, weight: isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? Palette.accentStrong : Palette.subtext)
                    .frame(maxWidth: .infinity)
                    .frame(height: 24)
                    .background(SettingsTile.fill(isSelected: isSelected), in: .capsule)
                    .overlay {
                        Capsule()
                            .stroke(SettingsTile.stroke(isSelected: isSelected), lineWidth: 1)
                    }
            }
        }
        .padding(.horizontal, 12)
    }

    var period: some View {
        VStack(spacing: 4) {
            Text("11月の始まり")
                .textFont(size: .caption)
                .foregroundStyle(Palette.subtext)

            HStack(spacing: 4) {
                Text("25日(日)")
                    .strikethrough()
                    .foregroundStyle(Palette.hint)

                Image(systemName: "arrow.right")
                    .foregroundStyle(Palette.hint)

                Text("23日(金)")
                    .bold()
                    .foregroundStyle(Palette.accentStrong)
            }
            .textFont(size: .caption)

            Text("10/23〜11/24")
                .displayFont(.body, weight: .bold)
                .foregroundStyle(Palette.accentStrong)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Palette.accent.opacity(.subtle), in: .capsule)
        }
        .monospacedDigit()
    }
}
