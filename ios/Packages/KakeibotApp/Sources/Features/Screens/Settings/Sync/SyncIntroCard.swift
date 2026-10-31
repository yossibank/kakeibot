import DesignSystem
import SwiftUI

struct SyncIntroCard: View {
    var body: some View {
        SettingsIntroCard(
            systemImage: "icloud",
            headline: ("自分の端末どうしでも", "家族やパートナーとも"),
            notes: [
                .init("iphone", "自分の iPhone・iPad で同じ記録を使えます"),
                .init("person.2", "口座ごとに、ほかの人と共有できます"),
                .init("iphone.and.arrow.forward", "機種変更しても、記録が残ります"),
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
