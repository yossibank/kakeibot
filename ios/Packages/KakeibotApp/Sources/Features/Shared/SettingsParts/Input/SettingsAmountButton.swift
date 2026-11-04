import DesignSystem
import SwiftUI

struct SettingsAmountButton: View {
    let amount: Int
    let text: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .trailing) {
                if let text {
                    Text(text)
                        .displayFont(.headline, weight: .bold)
                        .foregroundStyle(Palette.accentStrong)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity)
                } else {
                    SettingsKeypadValue(amount)
                        .frame(maxWidth: .infinity)
                }

                EditBadge(size: 16)
            }
            .frame(minHeight: 56)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
