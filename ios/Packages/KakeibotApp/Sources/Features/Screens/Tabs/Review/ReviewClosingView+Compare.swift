import Core
import DesignSystem
import SwiftUI

extension ReviewClosingView {
    struct GoodItem: Identifiable {
        let id: String
        let systemImage: String
        let title: String
        let detail: String
        let value: String
    }

    var goodItems: [GoodItem] {
        let less = content.rows
            .filter { $0.row.tone == .less }
            .prefix(Self.goodLimit)
            .map { item in
                GoodItem(
                    id: item.name,
                    systemImage: "arrow.down",
                    title: "\(item.name)が少なめ",
                    detail: "平均 \(ReviewYen.text(item.row.average)) → \(ReviewYen.text(item.row.amount))",
                    value: ReviewYen.signed(item.row.difference)
                )
            }

        guard content.budgetStreak >= 2 else {
            return less
        }

        let budget = GoodItem(
            id: "budget",
            systemImage: "star",
            title: "\(content.budgetStreak) \(periodsUnit)つづけて予算の中",
            detail: "\(name)まで続いています",
            value: ""
        )

        return less + [budget]
    }

    var compareCard: some View {
        let scale = compareScale

        return VStack(alignment: .leading, spacing: 12) {
            ReviewReportLabel(title: "いつもと比べる")

            VStack(alignment: .leading, spacing: 2) {
                Text("\(content.averagePeriods) \(periodsUnit)の平均と")
                    .displayFont(.headline, weight: .bold)
                    .foregroundStyle(Palette.text)

                Text("◆ が平均、● が\(name)です")
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
            }

            VStack(spacing: 0) {
                ForEach(content.rows) { item in
                    compareRow(item, scale: scale)
                }
            }

            if let special = content.special {
                specialCard(special)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(cornerRadius: 24)
    }

    var goodCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            ReviewReportLabel(title: "よかったこと")

            VStack(spacing: 0) {
                ForEach(goodItems) { item in
                    goodRow(item, isLast: item.id == goodItems.last?.id)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(cornerRadius: 24)
    }
}

private extension ReviewClosingView {
    static let goodLimit = 2

    static var specialFill: LinearGradient {
        LinearGradient(
            colors: [Palette.amber.opacity(.medium), Palette.amber],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var specialGlow: LinearGradient {
        LinearGradient(
            colors: [Palette.amber.opacity(.subtle), Palette.amber.opacity(.faint)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var compareScale: Int {
        let largest = content.rows.map { max($0.row.amount, $0.row.average) }.max() ?? 0
        return max(largest * 5 / 4, 1)
    }

    func compareRow(
        _ item: CompareRow,
        scale: Int
    ) -> some View {
        let row = item.row
        let color = Self.color(of: row.tone)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(item.name)
                    .textFont(.subheadline, weight: .bold)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(Self.toneText(row.tone))
                    .textFont(.caption2, weight: .bold)
                    .foregroundStyle(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(color.opacity(.subtle), in: Capsule())
                    .fixedSize()

                Spacer(minLength: 8)

                Text(ReviewYen.text(row.amount))
                    .displayFont(.body, weight: .bold)
                    .foregroundStyle(Palette.text)
                    .monospacedDigit()
                    .fixedSize()
            }

            track(row, scale: scale, color: color)

            HStack {
                Text("平均 \(ReviewYen.text(row.average))")
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
                    .monospacedDigit()

                Spacer(minLength: 8)

                Text(ReviewYen.signed(row.difference))
                    .textFont(.caption, weight: .bold)
                    .foregroundStyle(color)
                    .monospacedDigit()
            }

            if let why = notes.whys[item.id] {
                Button {
                    onOpenWhy(item, why)
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Image(systemName: "sparkles")
                            .sansFont(.micro, weight: .bold)
                            .foregroundStyle(Palette.gold)

                        ReviewEmphasisText(
                            parts: ReviewEmphasisText.parts(of: why),
                            face: .text(.caption),
                            weight: nil,
                            numberFace: .display(.body),
                            color: Palette.text
                        )
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                        DisclosureMark(.strongLink)
                            .foregroundStyle(Palette.accent)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Palette.accent.opacity(.faint), in: .rect(cornerRadius: 12))
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 12)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Palette.line)
                .frame(height: 1)
        }
    }

    func track(
        _ row: ReviewCompare.Row,
        scale: Int,
        color: Color
    ) -> some View {
        let amount = CGFloat(row.amount) / CGFloat(scale)
        let average = CGFloat(row.average) / CGFloat(scale)

        return GeometryReader { proxy in
            let width = proxy.size.width

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Palette.accent.opacity(.subtle))
                    .frame(height: 6)

                Capsule()
                    .fill(color)
                    .frame(width: width * amount, height: 6)

                RoundedRectangle(cornerRadius: 2)
                    .fill(Palette.card)
                    .strokeBorder(Palette.text, lineWidth: 2)
                    .frame(width: 10, height: 10)
                    .rotationEffect(.degrees(45))
                    .offset(x: width * average - 5)

                Circle()
                    .fill(color)
                    .stroke(Palette.card, lineWidth: 3)
                    .frame(width: 12, height: 12)
                    .offset(x: width * amount - 6)
            }
            .frame(height: 14)
        }
        .frame(height: 14)
    }

    func specialCard(_ special: Special) -> some View {
        let date = special.date.monthDayText
        let amount = ReviewYen.number(special.amount)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .sansFont(.small, weight: .bold)
                    .foregroundStyle(Palette.cardBottom)
                    .frame(width: 32, height: 32)
                    .background(Self.specialFill, in: .rect(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 0) {
                    Text("特別な支出")
                        .textFont(.caption2, weight: .bold)
                        .tracking(1.5)
                        .foregroundStyle(Palette.amber)

                    Text(special.name)
                        .displayFont(style: .subheadline, weight: .bold)
                        .foregroundStyle(Palette.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 8)

                Text(date)
                    .textFont(.caption2, weight: .bold)
                    .foregroundStyle(Palette.amber)
                    .monospacedDigit()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .overlay {
                        Capsule()
                            .strokeBorder(Palette.amber.opacity(.medium))
                    }
                    .fixedSize()
            }

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("平均の計算から外しています")
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 0)

                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(amount)
                        .displayFont(.headline, weight: .bold)
                        .monospacedDigit()

                    Text("円")
                        .displayFont(.small, weight: .bold)
                }
                .foregroundStyle(Palette.amber)
                .fixedSize()
            }
            .padding(.top, 12)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Palette.amber.opacity(.soft))
                    .frame(height: 1)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Self.specialGlow)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Palette.amber.opacity(.muted))
                }
        }
    }

    func goodRow(
        _ item: GoodItem,
        isLast: Bool
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.systemImage)
                .sansFont(.small, weight: .bold)
                .foregroundStyle(Palette.accent)
                .frame(width: 36, height: 36)
                .background(Palette.accent.opacity(.subtle), in: .rect(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .textFont(.subheadline, weight: .bold)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(item.detail)
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 8)

            Text(item.value)
                .displayFont(.body, weight: .bold)
                .foregroundStyle(Palette.accent)
                .monospacedDigit()
                .fixedSize()
        }
        .padding(.top, 12)
        .padding(.bottom, isLast ? 0 : 12)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Palette.line)
                .frame(height: 1)
        }
    }

    static func color(of tone: ReviewCompare.Tone) -> Color {
        switch tone {
        case .more: Palette.increase
        case .less: Palette.accent
        case .usual: Palette.subtext
        }
    }

    static func toneText(_ tone: ReviewCompare.Tone) -> String {
        switch tone {
        case .more: "多め"
        case .less: "少なめ"
        case .usual: "いつもどおり"
        }
    }
}
