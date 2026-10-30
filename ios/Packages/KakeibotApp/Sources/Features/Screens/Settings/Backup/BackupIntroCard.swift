import DesignSystem
import SwiftUI

struct BackupIntroCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "doc.on.doc")
                    .sansFont(.body, weight: .light)
                    .foregroundStyle(Palette.accent)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Circle()
                            .stroke(Palette.outline, lineWidth: 0.8)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text("記録と設定を、まとめて")

                    Text("1 つのファイルに残せます")
                }
                .displayFont(.body, weight: .medium)
                .foregroundStyle(Palette.accentStrong)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }

            Hairline()

            VStack(alignment: .leading, spacing: 12) {
                note("iphone.and.arrow.forward", "機種変更の前に書き出すと、戻せます")

                note("tablecells", "記録は、表計算用にも書き出せます")

                note("arrow.uturn.backward", "読み込む前のデータは退避します")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}

private extension BackupIntroCard {
    func note(
        _ systemImage: String,
        _ text: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .sansFont(.caption, weight: .medium)
                .foregroundStyle(Palette.accent)
                .frame(width: 22)

            Text(text)
                .textFont(.footnote)
                .foregroundStyle(Palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

#Preview {
    BackupIntroCard()
        .padding()
        .background(Palette.background)
}
