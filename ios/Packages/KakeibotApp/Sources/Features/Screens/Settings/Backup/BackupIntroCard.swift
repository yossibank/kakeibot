import DesignSystem
import SwiftUI

struct BackupIntroCard: View {
    var body: some View {
        SettingsIntroCard(
            systemImage: "doc.on.doc",
            headline: ("記録と設定を、まとめて", "1 つのファイルに残せます"),
            notes: [
                .init("iphone.and.arrow.forward", "機種変更の前に書き出すと、戻せます"),
                .init("tablecells", "記録は、表計算用にも書き出せます"),
                .init("arrow.uturn.backward", "読み込む前のデータは退避します")
            ]
        )
    }
}

#Preview {
    BackupIntroCard()
        .padding()
        .background(Palette.background)
}
