import DesignSystem
import SwiftUI

struct EmptyNote: View {
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
        EmptyNote(text: "まだ記録がありません") {}

        EmptyNote(text: "この月の記録はありません", onRecord: nil)
    }
    .padding()
    .background(Palette.background)
}
