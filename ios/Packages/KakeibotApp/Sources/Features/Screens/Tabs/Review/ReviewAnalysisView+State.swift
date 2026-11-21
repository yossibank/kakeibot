import Core
import DesignSystem
import SwiftUI

extension ReviewAnalysisView {
    var failed: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.circle")
                    .sansFont(.headline)
                    .foregroundStyle(Palette.rose)

                VStack(alignment: .leading, spacing: 2) {
                    Text("分析できませんでした")
                        .displayFont(.body, weight: .bold)

                    Text("少し待ってから、もう一度できます")
                        .textFont(.caption)
                        .foregroundStyle(Palette.subtext)
                }
            }

            PrimaryButton("もう一度", action: onRetry)
        }
    }

    var loading: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            let turn = time.truncatingRemainder(dividingBy: 1.1) / 1.1
            let pulse = 0.35 + 0.65 * (1 + sin(time * 4.5)) / 2

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(Palette.accent.opacity(.subtle), lineWidth: 3)

                        Circle()
                            .trim(from: 0, to: 0.2)
                            .stroke(
                                Palette.accent,
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .rotationEffect(.degrees(turn * 360))

                        Image(systemName: "sparkle")
                            .sansFont(.body, weight: .bold)
                            .foregroundStyle(Palette.accent)
                    }
                    .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("分析しています")
                            .textFont(.subheadline, weight: .bold)

                        Text("\(currentSpan) の記録")
                            .textFont(.caption2)
                            .foregroundStyle(Palette.subtext)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    loadingStep("記録を読みました", detail: "\(entryCount) 件", pulse: nil)
                    loadingStep("前の\(unit)と比べました", detail: focusName, pulse: nil)
                    loadingStep("AI がまとめています", detail: nil, pulse: pulse)
                }
            }
        }
    }

    func needsRecords(_ count: Int) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    ForEach(0..<ReviewComment.minimumEntries, id: \.self) { index in
                        let fill = index < count ? Palette.accent : Color.clear

                        RoundedRectangle(cornerRadius: 4)
                            .fill(fill)
                            .overlay {
                                RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(
                                        Palette.accent.opacity(.medium),
                                        style: .dashed
                                    )
                            }
                            .frame(width: 14, height: 14)
                    }
                }

                Text("あと \(ReviewComment.minimumEntries - count) 件で分析できます")
                    .displayFont(.body, weight: .bold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            PrimaryButton("記録する", action: onRecord)
        }
    }
}

private extension ReviewAnalysisView {
    func loadingStep(
        _ title: String,
        detail: String?,
        pulse: Double?
    ) -> some View {
        HStack(spacing: 12) {
            if let pulse {
                Circle()
                    .fill(Palette.accent)
                    .frame(width: 8, height: 8)
                    .frame(width: 20, height: 20)
                    .overlay {
                        Circle()
                            .strokeBorder(Palette.accent, lineWidth: 2)
                    }
                    .opacity(pulse)
            } else {
                Image(systemName: "checkmark")
                    .sansFont(.micro, weight: .bold)
                    .foregroundStyle(Palette.backgroundBottom)
                    .frame(width: 20, height: 20)
                    .background(Palette.gold, in: Circle())
            }

            Text(title)
                .textFont(.footnote, weight: pulse == nil ? .regular : .bold)
                .foregroundStyle(pulse == nil ? Palette.text : Palette.accentStrong)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 8)

            if let detail {
                Text(detail)
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }
}
