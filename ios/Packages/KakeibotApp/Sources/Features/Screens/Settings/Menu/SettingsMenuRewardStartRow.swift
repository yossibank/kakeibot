import DesignSystem
import Store
import SwiftUI

struct SettingsMenuRewardStartRow: View {
    let database: AppDatabase

    var body: some View {
        VStack(spacing: 0) {
            Hairline()

            NavigationLink {
                RewardRuleListView(database: database)
            } label: {
                SettingsRow(
                    "ごほうび貯金を始める",
                    systemImage: "gift",
                    tint: nil,
                    trailingImage: "chevron.right",
                    accessory: SettingsRowValue?.none
                )
            }
        }
    }
}
