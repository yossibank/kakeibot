import DesignSystem
import SwiftUI

struct LoadFailedNotice: View {
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text("読み込めませんでした")
                .textFont(.footnote)
                .foregroundStyle(Palette.subtext)

            Button("もう一度読み込む", action: onRetry)
                .textFont(.caption)
                .foregroundStyle(Palette.accent)
                .frame(minHeight: 44)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

public extension View {
    func loadFailed(
        _ isFailed: Bool,
        onRetry: @escaping () -> Void
    ) -> some View {
        overlay {
            if isFailed {
                LoadFailedNotice(onRetry: onRetry)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background { Backdrop() }
            }
        }
    }
}
