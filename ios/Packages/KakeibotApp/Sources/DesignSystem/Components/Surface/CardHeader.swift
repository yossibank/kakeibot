import SwiftUI

public struct CardHeader<Accessory: View>: View {
    let title: String
    let systemImage: String?
    let note: String?
    let onClose: (() -> Void)?
    let accessory: Accessory

    public init(
        _ title: String,
        systemImage: String? = nil,
        note: String? = nil,
        onClose: (() -> Void)? = nil,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.title = title
        self.systemImage = systemImage
        self.note = note
        self.onClose = onClose
        self.accessory = accessory()
    }

    public var body: some View {
        HStack(spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .sansFont(.small, weight: .semibold)
                    .foregroundStyle(Palette.accent)
                    .frame(width: Self.iconSize, height: Self.iconSize)
                    .background(Palette.accent.opacity(.subtle), in: Circle())
            }

            SectionTitle(title)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .contentTransition(.numericText())

            Spacer(minLength: 8)

            if let note {
                Text(note)
                    .textFont(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            accessory

            if let onClose {
                RingButton(
                    systemImage: "xmark",
                    size: .small,
                    action: onClose
                )
            }
        }
        .frame(minHeight: Self.height)
    }
}

public extension CardHeader where Accessory == EmptyView {
    init(
        _ title: String,
        systemImage: String? = nil,
        note: String? = nil,
        onClose: (() -> Void)? = nil
    ) {
        self.init(
            title,
            systemImage: systemImage,
            note: note,
            onClose: onClose
        ) {
            EmptyView()
        }
    }
}

private extension CardHeader {
    static var iconSize: CGFloat {
        26
    }

    static var height: CGFloat {
        44
    }
}

#Preview {
    VStack(spacing: 16) {
        CardHeader("最近の記録")
        CardHeader("これからの引き落とし", note: "合計 ¥32,000")
        CardHeader("資産", systemImage: "yensign", note: "3 口座")
        CardHeader("あと 2 つで準備がそろいます") {}
    }
    .padding(.horizontal, 16)
    .card()
    .padding()
    .background(Palette.background)
}
