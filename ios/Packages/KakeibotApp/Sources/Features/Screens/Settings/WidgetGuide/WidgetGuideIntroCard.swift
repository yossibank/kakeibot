import DesignSystem
import SwiftUI

struct WidgetGuideIntroCard: View {
    private let flag: SettingsScreenFlag?

    init(flag: SettingsScreenFlag? = nil) {
        self.flag = flag
    }

    var body: some View {
        SettingsIntroCard(
            systemImage: "square.grid.2x2",
            headline: ("アプリを開かずに", "記録と残りを見られます"),
            notes: [
                .init("bolt", "テンプレートを押すだけで記録できます"),
                .init("yensign.circle", "今月あといくら使えるかを見られます"),
                .init("lock", "ロック画面などにも置けます")
            ],
            flag: flag
        )
    }
}

#Preview {
    WidgetGuideIntroCard()
        .padding()
        .background(Palette.background)
}
