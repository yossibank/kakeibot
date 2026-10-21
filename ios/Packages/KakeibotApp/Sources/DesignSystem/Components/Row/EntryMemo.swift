import SwiftUI

struct EntryMemo: View {
    @State private var isExpanded = false
    @State private var fullHeight: CGFloat = 0
    @State private var shownHeight: CGFloat = 0
    @State private var lineHeight: CGFloat = 0

    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        let limit = isExpanded ? nil : Self.lineLimit

        VStack(alignment: .trailing, spacing: 2) {
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
                    measure
                }
                .mask {
                    fade
                }
                .overlay(alignment: .bottomTrailing) {
                    if isTruncated {
                        toggleLabel("続き", systemImage: "chevron.down")
                    }
                }

            if isExpanded {
                toggleLabel("閉じる", systemImage: "chevron.up")
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
    var measure: some View {
        ZStack(alignment: .topLeading) {
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { height in
                    fullHeight = height
                }

            Text(verbatim: " ")
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { height in
                    lineHeight = height
                }
        }
        .textFont(.caption)
        .hidden()
    }

    var fade: some View {
        let width: CGFloat = isTruncated ? Self.fadeWidth : 0

        return VStack(spacing: 0) {
            Rectangle()

            HStack(spacing: 0) {
                Rectangle()

                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .clear, location: 0.6)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: width)
            }
            .frame(height: lineHeight)
        }
    }

    func toggleLabel(
        _ title: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 3) {
            Text(title)
                .textFont(.caption, weight: .semibold)

            Image(systemName: systemImage)
                .sansFont(.micro, weight: .bold)
        }
        .foregroundStyle(Palette.accent)
    }
}

private extension EntryMemo {
    static let lineLimit = 2
    static let fadeWidth: CGFloat = 96

    var isTruncated: Bool {
        !isExpanded && fullHeight > shownHeight + 1
    }

    var canExpand: Bool {
        isExpanded || isTruncated
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
