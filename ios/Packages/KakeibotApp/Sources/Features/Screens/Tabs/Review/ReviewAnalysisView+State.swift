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

            rewriteButton
        }
    }

    var loading: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("記録を読んでいます")
                .textFont(.footnote)
                .foregroundStyle(Palette.subtext)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Self.loadingBars.indices, id: \.self) { index in
                    let bar = Self.loadingBars[index]

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Palette.accent.opacity(bar.opacity).gradient)
                        .frame(height: bar.height)
                }
            }
            .frame(height: 48, alignment: .bottom)
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
    struct LoadingBar: Hashable {
        let height: CGFloat
        let opacity: Double
    }

    static let loadingBars = [
        LoadingBar(height: 14, opacity: 0.25),
        LoadingBar(height: 26, opacity: 0.35),
        LoadingBar(height: 20, opacity: 0.45),
        LoadingBar(height: 38, opacity: 0.6),
        LoadingBar(height: 30, opacity: 0.75),
        LoadingBar(height: 48, opacity: 1)
    ]
}
