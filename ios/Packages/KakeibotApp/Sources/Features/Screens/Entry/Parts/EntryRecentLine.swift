import SwiftUI

struct EntryRecentLine<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 8) {
            content
        }
    }
}
