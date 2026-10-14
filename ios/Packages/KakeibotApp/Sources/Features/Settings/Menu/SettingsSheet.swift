import DesignSystem
import SwiftUI

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Color.clear
                    .frame(width: 44, height: 44)

                Spacer()

                Text("設定")
                    .font(.system(size: 16, design: .serif))
                    .tracking(4)
                    .foregroundStyle(Palette.gold)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                RingButton("閉じる", systemImage: "xmark") {
                    dismiss()
                }
            }

            ContentUnavailableView(
                "設定は準備中です",
                systemImage: "gearshape",
                description: Text("カテゴリの編集から順に足していきます")
            )
            .foregroundStyle(Palette.mist)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            Rectangle()
                .fill(Palette.night)
                .ignoresSafeArea()
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    SettingsSheet()
}
