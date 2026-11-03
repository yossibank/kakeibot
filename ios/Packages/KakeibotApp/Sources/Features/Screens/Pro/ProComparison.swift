import DesignSystem
import SwiftUI

struct ProComparison: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsSectionTitle("無料と Pro")

            Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 0) {
                GridRow {
                    Color.clear
                        .frame(height: 1)

                    header("無料")

                    header("Pro")
                }
                .padding(.bottom, 8)

                ForEach(Self.rows) { row in
                    Divider()
                        .overlay(Palette.hairline)

                    GridRow(alignment: .firstTextBaseline) {
                        Text(row.title)
                            .textFont(.footnote)
                            .foregroundStyle(Palette.text)
                            .fixedSize(horizontal: false, vertical: true)

                        mark(row.free, isPro: false)

                        mark(row.pro, isPro: true)
                    }
                    .padding(.vertical, 11)
                }
            }
            .padding(16)
            .card()
        }
    }
}

private extension ProComparison {
    struct Row: Identifiable {
        let title: String
        let free: Mark
        let pro: Mark

        var id: String {
            title
        }
    }

    enum Mark {
        case yes
        case no
        case text(String)
    }

    static let columnWidth: CGFloat = 76

    static let rows = [
        Row(title: "記録・予算・振り返り", free: .yes, pro: .yes),
        Row(title: "ウィジェット・バックアップ", free: .yes, pro: .yes),
        Row(title: "レシートの読み取り", free: .text("3 回まで"), pro: .text("制限なし")),
        Row(title: "端末間の同期", free: .no, pro: .yes),
        Row(title: "家族との共有", free: .text("招待されたら"), pro: .yes),
        Row(title: "テーマを作る", free: .no, pro: .yes),
        Row(title: "4 つの字体", free: .no, pro: .yes)
    ]
}

private extension ProComparison {
    func header(_ title: String) -> some View {
        Text(title)
            .textFont(.caption, weight: .bold)
            .tracking(1)
            .foregroundStyle(title == "Pro" ? Palette.accentStrong : Palette.subtext)
            .frame(width: Self.columnWidth)
    }

    @ViewBuilder
    func mark(
        _ mark: Mark,
        isPro: Bool
    ) -> some View {
        let color = isPro ? Palette.accentStrong : Palette.subtext

        Group {
            switch mark {
            case .yes:
                Image(systemName: isPro ? "checkmark.circle.fill" : "checkmark")
                    .textFont(.footnote, weight: .semibold)
            case .no:
                Text("—")
                    .textFont(.footnote)
                    .foregroundStyle(Palette.hint)
            case let .text(text):
                Text(text)
                    .textFont(.caption2, weight: isPro ? .bold : .regular)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .foregroundStyle(color)
        .frame(width: Self.columnWidth)
    }
}
