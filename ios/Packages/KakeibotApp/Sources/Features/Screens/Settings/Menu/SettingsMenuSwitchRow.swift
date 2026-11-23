import DesignSystem
import SwiftUI

struct SettingsMenuSwitchRow: View {
    let title: String
    let systemImage: String
    let isOn: Binding<Bool>

    init(
        _ title: String,
        systemImage: String,
        isOn: Binding<Bool>
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isOn = isOn
    }

    var body: some View {
        GoldSwitch(
            isOn: isOn,
            systemImage: systemImage,
            insets: EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0)
        ) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .sansFont(.body, weight: .light)
                    .foregroundStyle(Palette.accent)
                    .frame(width: 22)

                Text(title)
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }
}
