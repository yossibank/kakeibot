import DesignSystem
import SwiftUI

struct PlaceholderEmpty: View {
    let text: String
    let onRecord: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Text(text)
                .textFont(.footnote)
                .foregroundStyle(Palette.subtext)
                .multilineTextAlignment(.center)

            if let onRecord {
                PrimaryButton("記録する", action: onRecord)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    VStack(spacing: 40) {
        PlaceholderEmpty(text: "まだ記録がありません") {}
        PlaceholderEmpty(text: "この月の記録はありません", onRecord: nil)
    }
    .padding()
    .background(Palette.background)
}
