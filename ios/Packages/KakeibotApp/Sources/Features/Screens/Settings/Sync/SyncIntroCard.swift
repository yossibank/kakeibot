import DesignSystem
import SwiftUI

struct SyncIntroCard: View {
    var body: some View {
        SettingsIntroCard(
            systemImage: "icloud",
            headline: ("自分の iPhone・iPad で", "同じ記録を使えます"),
            notes: [
                .init("arrow.triangle.2.circlepath", "同じ Apple ID の端末どうしでそろいます"),
                .init("iphone.and.arrow.forward", "機種変更しても、記録が残ります"),
                .init("person.2", "ほかの人とは、口座ごとに共有できます"),
                .init("lock", "記録は暗号化して iCloud に置きます")
            ]
        )
    }
}

#Preview {
    SyncIntroCard()
        .padding()
        .background(Palette.background)
}
