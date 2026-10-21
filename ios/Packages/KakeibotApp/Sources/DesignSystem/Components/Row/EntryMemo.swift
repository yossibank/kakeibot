import SwiftUI

struct EntryMemo: View {
    @State private var isExpanded = false
    @State private var fullHeight: CGFloat = 0
    @State private var shownHeight: CGFloat = 0

    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        let limit = isExpanded ? nil : Self.lineLimit
        let angle = isExpanded ? 180.0 : 0

        HStack(alignment: .lastTextBaseline, spacing: 4) {
            Text(text)
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .lineLimit(limit)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { height in
                    shownHeight = height
                }
                .background(alignment: .topLeading) {
                    Text(text)
                        .textFont(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                        .hidden()
                        .onGeometryChange(for: CGFloat.self) { proxy in
                            proxy.size.height
                        } action: { height in
                            fullHeight = height
                        }
                }

            if canExpand {
                Image(systemName: "chevron.down")
                    .sansFont(.micro, weight: .bold)
                    .foregroundStyle(Palette.accent)
                    .rotationEffect(.degrees(angle))
            }
        }
        .padding(.leading, 8)
        .overlay(alignment: .leading) {
            Capsule()
                .fill(Palette.accent.opacity(.medium))
                .frame(width: 2)
        }
        .contentShape(.rect)
        .onTapGesture {
            toggle()
        }
        .allowsHitTesting(canExpand)
        .sensoryFeedback(.selection, trigger: isExpanded)
    }
}

private extension EntryMemo {
    static let lineLimit = 2

    var canExpand: Bool {
        isExpanded || fullHeight > shownHeight + 1
    }

    func toggle() {
        withAnimation(.snappy(duration: 0.25)) {
            isExpanded.toggle()
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        EntryMemo("ランチ")
        EntryMemo(
            "同僚と駅前の新しいイタリアンでランチ。パスタとサラダのセットに、"
                + "食後のコーヒーとデザートも付けた。次は夜に来てみたい"
        )
    }
    .padding()
    .background(Palette.background)
}
