import DesignSystem
import FeatureModels
import Store
import SwiftUI

struct SettingsMenuRewardStartRow: View {
    let parts: ScreenParts

    var body: some View {
        VStack(spacing: 0) {
            Hairline()

            NavigationLink {
                RewardRuleListView(parts: parts)
            } label: {
                SettingsMenuRow(
                    "ごほうび貯金を始める",
                    systemImage: "gift",
                    tint: nil,
                    trailingImage: "chevron.right",
                    accessory: SettingsMenuRowValue?.none
                )
            }
        }
    }
}
