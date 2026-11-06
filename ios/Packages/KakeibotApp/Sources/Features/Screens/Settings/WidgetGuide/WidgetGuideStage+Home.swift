import Core
import DesignSystem
import SwiftUI

extension WidgetGuideStage {
    var budget: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                Text("今月あといくら")
                    .textFont(size: .caption)
                    .tracking(1)
                    .foregroundStyle(Palette.accent)

                Spacer(minLength: 4)

                ZStack(alignment: .bottom) {
                    HalfDial(progress: 0.62)

                    AmountText(
                        FeatureArtSample.remaining,
                        font: .size(.headline, weight: .bold),
                        color: Palette.accentStrong
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 4)

                Text("予算 \(AmountText.text(200_000))")
                    .textFont(size: .caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text("今日の支出")
                        .textFont(size: .caption)
                        .foregroundStyle(Palette.subtext)

                    Spacer(minLength: 4)

                    Text("あと 12 日")
                        .textFont(size: .micro)
                        .foregroundStyle(Palette.subtext)
                }

                AmountText(
                    FeatureArtSample.todayExpense,
                    font: .size(.title, weight: .bold),
                    color: Palette.accentStrong
                )

                Rectangle()
                    .fill(Palette.line)
                    .frame(height: 1)
                    .padding(.vertical, 8)

                VStack(spacing: 4) {
                    row("今週の支出", amount: FeatureArtSample.weekExpense)
                    row("今月の支出", amount: FeatureArtSample.monthExpense)
                    row("家賃 11/27", amount: 85000)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .frame(height: Self.widgetHeight)
        .card(cornerRadius: Self.widgetRadius)
    }

    var budgetSmall: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text("今月あといくら")
                        .textFont(size: .caption)
                        .tracking(1)
                        .foregroundStyle(Palette.accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    Spacer(minLength: 4)

                    Text("あと 12 日")
                        .textFont(size: .micro)
                        .foregroundStyle(Palette.subtext)
                        .fixedSize()
                }

                Spacer(minLength: 4)

                ZStack(alignment: .bottom) {
                    HalfDial(progress: 0.62)

                    AmountText(
                        FeatureArtSample.remaining,
                        font: .size(.headline, weight: .bold),
                        color: Palette.accentStrong
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 4)

                HStack(alignment: .firstTextBaseline) {
                    Text("今日の支出")
                        .textFont(size: .caption)
                        .foregroundStyle(Palette.subtext)

                    Spacer(minLength: 4)

                    AmountText(
                        FeatureArtSample.todayExpense,
                        font: .size(.small, weight: .semibold),
                        color: Palette.text
                    )
                }
            }
            .padding(12)
            .frame(width: Self.widgetHeight, height: Self.widgetHeight)
            .card(cornerRadius: Self.widgetRadius)

            Grid(horizontalSpacing: 22, verticalSpacing: 22) {
                GridRow {
                    app(Self.apps[0])
                    app(Self.apps[1])
                }

                GridRow {
                    app(Self.apps[2])
                    app(Self.apps[3])
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    var quickRecordLarge: some View {
        VStack(spacing: 4) {
            quickRecordHeader
                .frame(height: 20)

            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                ForEach(0..<3, id: \.self) { row in
                    GridRow {
                        tile(Self.tiles[row * 2], showsDetail: true)
                        tile(Self.tiles[row * 2 + 1], showsDetail: true)
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)

            Rectangle()
                .fill(Palette.line)
                .frame(height: 1)
                .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text("今日の記録 3 件")
                        .textFont(size: .micro)
                        .tracking(1)
                        .foregroundStyle(Palette.accent)

                    Spacer(minLength: 4)

                    Text("ほか 1 件")
                        .textFont(size: .micro)
                        .foregroundStyle(Palette.subtext)
                }

                ForEach(Self.records, id: \.self) { record in
                    recordRow(record)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .frame(height: Self.largeHeight)
        .card(cornerRadius: Self.widgetRadius)
    }

    var quickRecordHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("すぐ記録")
                .textFont(size: .caption)
                .foregroundStyle(Palette.accent)

            Spacer(minLength: 4)

            Text("今日の支出 \(AmountText.text(FeatureArtSample.todayExpense))")
                .textFont(size: .caption)
                .monospacedDigit()
                .foregroundStyle(Palette.subtext)
        }
    }

    var quickRecord: some View {
        VStack(spacing: 4) {
            quickRecordHeader
                .frame(height: 20)

            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                GridRow {
                    tile(Self.tiles[0])
                    tile(Self.tiles[1])
                }

                GridRow {
                    tile(Self.tiles[2])
                    tile(Self.tiles[3])
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .frame(height: Self.widgetHeight)
        .card(cornerRadius: Self.widgetRadius)
    }
}

private extension WidgetGuideStage {
    func row(
        _ title: String,
        amount: Int
    ) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .textFont(size: .caption)
                .foregroundStyle(Palette.subtext)

            Spacer(minLength: 6)

            AmountText(amount, font: .size(.small, weight: .medium), color: Palette.text)
        }
    }

    func app(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 24))
            .foregroundStyle(Palette.accent)
            .frame(width: Self.appSize, height: Self.appSize)
            .background(Palette.card.opacity(0.8), in: .rect(cornerRadius: 16))
    }

    func badge(_ systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: 10))
            .foregroundStyle(Palette.accent)
            .frame(width: Self.markSize, height: Self.markSize)
            .background(Palette.faint, in: Circle())
    }

    func recordRow(_ record: Record) -> some View {
        HStack(spacing: 8) {
            badge(record.systemImage)

            VStack(alignment: .leading, spacing: 1) {
                Text(record.title)
                    .textFont(size: .caption, weight: .medium)
                    .foregroundStyle(Palette.text)

                Text(record.detail)
                    .textFont(size: .micro)
                    .foregroundStyle(Palette.subtext)
            }

            Spacer(minLength: 8)

            AmountText(record.amount, font: .size(.small, weight: .medium), color: Palette.text)
        }
    }

    func tile(
        _ tile: Tile,
        showsDetail: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                badge(tile.systemImage)

                Text(tile.name)
                    .textFont(size: .caption, weight: .medium)
                    .foregroundStyle(Palette.accentStrong)
                    .lineLimit(1)
            }

            if showsDetail {
                Text(tile.detail)
                    .textFont(size: .micro)
                    .foregroundStyle(Palette.subtext)
                    .lineLimit(1)
                    .padding(.leading, Self.markSize + 4)
            }

            Spacer(minLength: 2)

            HStack(spacing: 4) {
                if let amount = tile.amount {
                    AmountText(
                        amount,
                        font: .size(.body, weight: .medium),
                        color: Palette.accentStrong
                    )
                } else {
                    Text("毎回入れる")
                        .textFont(size: .micro)
                        .foregroundStyle(Palette.hint)
                }

                Spacer(minLength: 0)

                if tile.amount == nil {
                    EditBadge(size: Self.markSize)
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Palette.backgroundTop)
                        .frame(width: Self.markSize, height: Self.markSize)
                        .background(Palette.accent, in: Circle())
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .templateCardFace(cornerRadius: Self.tileRadius, shadowRadius: 3)
    }
}
