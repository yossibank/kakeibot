import Core
import DesignSystem
import SwiftUI

struct EntryRecentRow<Content: View>: View {
    let title: String

    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .textFont(.caption2, weight: .bold)
                .foregroundStyle(Palette.subtext)
                .padding(.horizontal, 4)

            ScrollView(.horizontal) {
                VStack(alignment: .leading, spacing: 8) {
                    content
                }
                .padding(.vertical, 1)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        }
    }
}
