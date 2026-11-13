import Core
import DesignSystem
import SwiftUI

struct EntryVoiceCard: View {
    @Environment(\.themeStyle.corner) private var corner

    let flow: EntryVoiceFlow
    let model: EntryModel
    let today: LocalDate
    let onCancel: () -> Void
    let onFinish: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if flow.step == .denied {
                denied
            } else {
                listening
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: Self.minHeight, alignment: .top)
        .background(Palette.card, in: .rect(cornerRadius: corner.radius(20)))
        .overlay {
            RoundedRectangle(cornerRadius: corner.radius(20))
                .stroke(Palette.outline, lineWidth: 1)
        }
    }
}

private extension EntryVoiceCard {
    static let minHeight: CGFloat = 268
    static let transcriptHeight: CGFloat = 92
    static let example = "例：昨日 ランチ 980円 カードで"
    static let largeTextLimit = 36
    static let mediumTextLimit = 64
    static let cancelWidth: CGFloat = 104
    static let waveHeight: CGFloat = 24

    var isReading: Bool {
        flow.step == .reading
    }

    var transcriptStyle: Font.TextStyle {
        switch flow.transcript.text.count {
        case ..<Self.largeTextLimit: .title3
        case ..<Self.mediumTextLimit: .body
        default: .subheadline
        }
    }

    var spoken: AttributedString {
        var settled = AttributedString(flow.transcript.settled)
        settled.foregroundColor = Palette.accentStrong

        var pending = AttributedString(flow.transcript.pending)
        pending.foregroundColor = Palette.subtext

        return settled + pending
    }

    var slotShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(16))
    }

    var listening: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                if isReading {
                    Text("読んでいます")
                        .textFont(.caption, weight: .semibold)
                        .tracking(2)
                        .foregroundStyle(Palette.accent)

                    Spacer(minLength: 0)

                    ProgressView()
                        .controlSize(.small)
                        .tint(Palette.accent)
                } else {
                    EntryVoiceWave(
                        flow: flow,
                        reach: EntryVoiceFlow.levelCount - 1,
                        height: Self.waveHeight
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: Self.waveHeight)

            transcript
                .frame(height: Self.transcriptHeight, alignment: .topLeading)
                .clipped()

            slots

            HStack(spacing: 8) {
                Text("黙ると聞き終えます")
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)
                    .fixedSize()

                EntryVoiceCountdown(
                    start: flow.silenceStart,
                    duration: flow.silenceDuration,
                    isSpent: isReading
                )
            }

            HStack(spacing: 8) {
                CardButton("やめる", style: .outlined(Palette.subtext), height: 44, action: onCancel)
                    .frame(width: Self.cancelWidth)

                CardButton("話し終えた", style: .filled, height: 44, action: onFinish)
            }
            .disabled(isReading)
            .opacity(isReading ? 0.5 : 1)
        }
    }

    var transcript: some View {
        ScrollView {
            Group {
                if flow.transcript.isEmpty {
                    Text("話してください\n\(Self.example)")
                        .foregroundStyle(Palette.hint)
                } else {
                    Text(spoken)
                }
            }
            .displayFont(style: transcriptStyle)
            .lineSpacing(2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .defaultScrollAnchor(.bottom, for: .initialOffset)
        .defaultScrollAnchor(.bottom, for: .sizeChanges)
    }

    var slots: some View {
        let reading = flow.preview

        return SlotRows(spacing: 8) {
            slot(
                systemImage: "square.grid.2x2",
                label: "カテゴリ",
                value: reading?.categoryId.flatMap { id in
                    model.categories.first { $0.id == id }?.name
                }
            )

            slot(
                systemImage: "calendar",
                label: "日付",
                value: reading?.date.map { EntryModel.shortDateText(for: $0, today: today) }
            )

            slot(
                systemImage: "creditcard",
                label: "口座",
                value: reading?.walletId.flatMap { id in
                    model.wallets.first { $0.id == id }?.name
                }
            )

            slot(
                systemImage: "pencil",
                label: "メモ",
                value: reading?.memo
            )
        }
        .animation(.snappy, value: reading)
    }

    var denied: some View {
        VStack(spacing: 12) {
            Image(systemName: "mic.slash")
                .sansFont(.headline, weight: .light)
                .foregroundStyle(Palette.accent)
                .frame(width: 52, height: 52)
                .overlay {
                    Circle()
                        .stroke(Palette.outline, lineWidth: 0.8)
                }

            Text("マイクが使えません")
                .displayFont(.headline, weight: .medium)
                .foregroundStyle(Palette.accentStrong)

            Text("声で記録するには、iPhone の設定で\nかけいぼっとの「マイク」と「音声認識」を入にしてください")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                CardButton("やめる", style: .outlined(Palette.subtext), height: 44, action: onCancel)
                    .frame(width: Self.cancelWidth)

                CardButton("設定を開く", style: .filled, height: 44, action: onOpenSettings)
            }
        }
        .frame(maxWidth: .infinity)
    }

    func slot(
        systemImage: String,
        label: String,
        value: String?
    ) -> some View {
        let isRead = value != nil

        return HStack(spacing: 4) {
            Image(systemName: systemImage)
                .sansFont(.micro, weight: .semibold)

            Text(value ?? label)
                .textFont(.caption2, weight: isRead ? .semibold : .regular)
                .lineLimit(2)
        }
        .foregroundStyle(isRead ? Palette.accentStrong : Palette.subtext)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .frame(minHeight: 28)
        .background(isRead ? Palette.faint : Color.clear, in: slotShape)
        .overlay {
            slotShape
                .stroke(
                    isRead ? Palette.accent : Palette.subtext.opacity(.muted),
                    style: isRead ? StrokeStyle(lineWidth: 1) : .dashed
                )
        }
        .transition(.scale(scale: 0.8).combined(with: .opacity))
    }
}

private struct SlotRows: Layout {
    let spacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let width = proposal.width ?? .infinity
        let frames = frames(of: subviews, width: width)
        let height = frames.map(\.maxY).max() ?? 0
        let usedWidth = frames.map(\.maxX).max() ?? 0
        return CGSize(width: proposal.width ?? usedWidth, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let frames = frames(of: subviews, width: bounds.width)

        for (subview, frame) in zip(subviews, frames) {
            subview.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    func frames(
        of subviews: Subviews,
        width: CGFloat
    ) -> [CGRect] {
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        return subviews.map { subview in
            let size = subview.sizeThatFits(ProposedViewSize(width: width, height: nil))
            let fitted = CGSize(width: min(size.width, width), height: size.height)

            if x > 0, x + fitted.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            let frame = CGRect(origin: CGPoint(x: x, y: y), size: fitted)
            x += fitted.width + spacing
            rowHeight = max(rowHeight, fitted.height)
            return frame
        }
    }
}
