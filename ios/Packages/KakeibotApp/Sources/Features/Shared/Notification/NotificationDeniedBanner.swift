import DesignSystem
import SwiftUI
import UIKit

struct NotificationDeniedBanner: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .sansFont(.small)

            Text("通知が届かない状態です")
                .textFont(.footnote, weight: .semibold)

            Spacer(minLength: 0)

            Button {
                openSettings()
            } label: {
                HStack(spacing: 2) {
                    Text("許可する")
                        .textFont(.caption, weight: .semibold)

                    Image(systemName: "chevron.right")
                        .sansFont(.micro, weight: .semibold)
                }
                .padding(.horizontal, 12)
                .frame(minHeight: 30)
                .background(Palette.rose.opacity(.subtle), in: Capsule())
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(Palette.rose)
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        .background(Palette.rose.opacity(.faint), in: Capsule())
        .overlay {
            Capsule()
                .stroke(Palette.rose.opacity(.muted), lineWidth: 1)
        }
    }
}

private extension NotificationDeniedBanner {
    func openSettings() {
        let link = UIApplication.openNotificationSettingsURLString

        guard let url = URL(string: link) else {
            return
        }

        openURL(url)
    }
}
