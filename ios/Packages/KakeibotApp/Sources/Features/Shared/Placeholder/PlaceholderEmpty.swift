import DesignSystem
import SwiftUI

struct PlaceholderEmpty<Action: View>: View {
    let systemImage: String
    let text: String
    let detail: String?
    let action: Action

    init(
        systemImage: String,
        text: String,
        detail: String? = nil,
        @ViewBuilder action: () -> Action
    ) {
        self.systemImage = systemImage
        self.text = text
        self.detail = detail
        self.action = action()
    }

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                Image(systemName: systemImage)
                    .sansFont(.title, weight: .ultraLight)
                    .foregroundStyle(Palette.accent)

                VStack(spacing: 4) {
                    Text(text)
                        .textFont(.footnote)
                        .foregroundStyle(Palette.subtext)

                    if let detail {
                        Text(detail)
                            .textFont(.caption)
                            .foregroundStyle(Palette.hint)
                    }
                }
                .multilineTextAlignment(.center)
            }

            action
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Self.verticalPadding)
    }
}

extension PlaceholderEmpty where Action == PrimaryButton? {
    init(
        systemImage: String,
        text: String,
        onRecord: (() -> Void)?
    ) {
        self.init(systemImage: systemImage, text: text) {
            onRecord.map {
                PrimaryButton("記録する", action: $0)
            }
        }
    }
}

private extension PlaceholderEmpty {
    static var verticalPadding: CGFloat {
        32
    }
}

#Preview {
    VStack(spacing: 0) {
        PlaceholderEmpty(systemImage: "square.and.pencil", text: "まだ記録がありません", onRecord: {})

        PlaceholderEmpty(systemImage: "calendar", text: "この月の記録はありません", onRecord: nil)

        PlaceholderEmpty(
            systemImage: "magnifyingglass",
            text: "「コーヒー」は見つかりませんでした",
            detail: "金額やメモの一部でも探せます"
        ) {
            EmptyView()
        }
    }
    .padding()
    .background(Palette.background)
}
