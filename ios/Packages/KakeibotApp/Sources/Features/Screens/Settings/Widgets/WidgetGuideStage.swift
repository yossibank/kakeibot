import Core
import DesignSystem
import SwiftUI

struct WidgetGuideStage: View {
    let place: WidgetGuidePlace
    let widget: WidgetGuideWidget
    let size: WidgetGuideSize

    var body: some View {
        FeatureArtCanvas(width: Self.width, height: height) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(14)
        .background(wallpaper, in: .rect(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .stroke(Palette.outline, lineWidth: 1)
        }
    }
}

private extension WidgetGuideStage {
    struct Tile: Hashable {
        let systemImage: String
        let name: String
        let detail: String
        let amount: Int?
    }

    struct Record: Hashable {
        let systemImage: String
        let title: String
        let detail: String
        let amount: Int
    }

    static let width: CGFloat = 338
    static let widgetHeight: CGFloat = 158
    static let largeHeight: CGFloat = 354
    static let appSize: CGFloat = 62
    static let widgetRadius: CGFloat = 22
    static let tileRadius: CGFloat = 12
    static let markSize: CGFloat = 20
    static let night = Color(red: 0.13, green: 0.14, blue: 0.16)
    static let nightTop = Color(red: 0.27, green: 0.29, blue: 0.33)

    static let tiles = [
        Tile(systemImage: "cup.and.saucer", name: "コーヒー", detail: "カフェ・財布", amount: 450),
        Tile(systemImage: "fork.knife", name: "お昼", detail: "食費・財布", amount: 800),
        Tile(systemImage: "tram", name: "電車", detail: "交通・カード", amount: 220),
        Tile(systemImage: "cart", name: "買い物", detail: "日用品・カード", amount: nil),
        Tile(systemImage: "book", name: "本", detail: "趣味・カード", amount: 1500),
        Tile(systemImage: "figure.run", name: "ジム", detail: "健康・銀行", amount: 800)
    ]

    static let records = [
        Record(systemImage: "fork.knife", title: "食費", detail: "お昼・財布", amount: 800),
        Record(systemImage: "cup.and.saucer", title: "カフェ", detail: "コーヒー・財布", amount: 450)
    ]

    static let apps = [
        "calendar",
        "camera",
        "map",
        "music.note"
    ]

    static let controls = [
        "airplane",
        "wifi",
        "flashlight.off.fill",
        "timer",
        "camera",
        "moon.fill",
        "plus.forwardslash.minus"
    ]
}

private extension WidgetGuideStage {
    var height: CGFloat {
        switch place {
        case .home: size == .large ? Self.largeHeight : Self.widgetHeight
        case .lockScreen: 236
        case .control: 214
        }
    }

    var wallpaper: AnyShapeStyle {
        switch place {
        case .home:
            AnyShapeStyle(
                LinearGradient(
                    colors: [Palette.accent.opacity(.soft), Palette.accent.opacity(.faint)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .lockScreen, .control:
            AnyShapeStyle(
                LinearGradient(
                    colors: [Self.nightTop, Self.night],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
}

private extension WidgetGuideStage {
    @ViewBuilder
    var content: some View {
        switch place {
        case .home:
            switch (widget, size) {
            case (.budget, .small):
                budgetSmall
            case (.budget, _):
                budget
            case (.quickRecord, .large):
                quickRecordLarge
            case (.quickRecord, _):
                quickRecord
            }
        case .lockScreen:
            lockScreen
        case .control:
            control
        }
    }

    var budget: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 0) {
                Text("今月あといくら")
                    .textFont(size: .caption)
                    .tracking(1)
                    .foregroundStyle(Palette.accent)

                Spacer(minLength: 4)

                ZStack(alignment: .bottom) {
                    HalfDial(progress: 0.62)

                    Text(AmountText.text(FeatureArtSample.remaining))
                        .displayFont(.headline, weight: .bold)
                        .monospacedDigit()
                        .foregroundStyle(Palette.accentStrong)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(.horizontal, 22)
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

                Text(AmountText.text(FeatureArtSample.todayExpense))
                    .displayFont(.title, weight: .bold)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)

                Rectangle()
                    .fill(Palette.line)
                    .frame(height: 1)
                    .padding(.vertical, 7)

                VStack(spacing: 6) {
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
        HStack(spacing: 22) {
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

                    Text(AmountText.text(FeatureArtSample.remaining))
                        .displayFont(.headline, weight: .bold)
                        .monospacedDigit()
                        .foregroundStyle(Palette.accentStrong)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(.horizontal, 22)
                }

                Spacer(minLength: 4)

                HStack(alignment: .firstTextBaseline) {
                    Text("今日の支出")
                        .textFont(size: .caption)
                        .foregroundStyle(Palette.subtext)

                    Spacer(minLength: 4)

                    Text(AmountText.text(FeatureArtSample.todayExpense))
                        .textFont(size: .small, weight: .semibold)
                        .monospacedDigit()
                        .foregroundStyle(Palette.text)
                }
            }
            .padding(14)
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
        VStack(spacing: 8) {
            quickRecordHeader

            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                ForEach(0..<3, id: \.self) { row in
                    GridRow {
                        tile(Self.tiles[row * 2], showsDetail: true)

                        tile(Self.tiles[row * 2 + 1], showsDetail: true)
                    }
                }
            }
            .frame(height: 198)

            Rectangle()
                .fill(Palette.line)
                .frame(height: 1)
                .padding(.vertical, 4)

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

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 14)
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
        VStack(spacing: 8) {
            quickRecordHeader

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
        .padding(.vertical, 12)
        .frame(height: Self.widgetHeight)
        .card(cornerRadius: Self.widgetRadius)
    }

    var lockScreen: some View {
        VStack(spacing: 4) {
            Label(
                "今月あと \(AmountText.text(FeatureArtSample.remaining))",
                systemImage: "yensign.circle"
            )
            .font(.system(size: 13, weight: .semibold))
            .monospacedDigit()
            .opacity(0.85)

            Text("9:41")
                .font(.system(size: 76, weight: .semibold, design: .rounded))
                .monospacedDigit()

            HStack(spacing: 12) {
                lockCircle

                lockRectangle
            }
            .padding(.top, 6)
        }
        .foregroundStyle(.white)
    }

    var lockCircle: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.3), lineWidth: 6)

            Circle()
                .trim(from: 0, to: 0.62)
                .stroke(.white, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Text("あと")
                    .font(.system(size: 9))

                Text("4.2万")
                    .font(.system(size: 15, weight: .bold))
                    .monospacedDigit()
            }
        }
        .padding(6)
        .frame(width: 72, height: 72)
        .background(.white.opacity(0.14), in: Circle())
    }

    var lockRectangle: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(alignment: .firstTextBaseline) {
                Text("今月あといくら")
                    .font(.system(size: 12))

                Spacer(minLength: 4)

                Text("あと 12 日")
                    .font(.system(size: 10))
                    .opacity(0.7)
            }

            Text(AmountText.text(FeatureArtSample.remaining))
                .font(.system(size: 22, weight: .bold))
                .monospacedDigit()

            Text("今日の支出 \(AmountText.text(FeatureArtSample.todayExpense))")
                .font(.system(size: 11))
                .monospacedDigit()
                .opacity(0.7)
        }
        .padding(.horizontal, 12)
        .frame(width: 176, height: 72)
        .background(.white.opacity(0.14), in: .rect(cornerRadius: 16))
    }

    var control: some View {
        Grid(horizontalSpacing: 14, verticalSpacing: 14) {
            GridRow {
                ForEach(Self.controls.prefix(4), id: \.self) { symbol in
                    controlButton(symbol)
                }
            }

            GridRow {
                ForEach(Self.controls.suffix(3), id: \.self) { symbol in
                    controlButton(symbol)
                }

                VStack(spacing: 6) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Self.night)
                        .frame(width: 62, height: 62)
                        .background(.white, in: Circle())
                        .overlay {
                            Circle()
                                .stroke(.white.opacity(0.5), lineWidth: 2)
                                .padding(-5)
                        }

                    Text("記録する")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
    }

    func row(
        _ title: String,
        amount: Int
    ) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .textFont(size: .caption)
                .foregroundStyle(Palette.subtext)

            Spacer(minLength: 6)

            Text(AmountText.text(amount))
                .displayFont(.small, weight: .medium)
                .monospacedDigit()
                .foregroundStyle(Palette.text)
        }
    }

    func controlButton(_ symbol: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 20))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 62, height: 62)
                .background(.white.opacity(0.14), in: Circle())

            Text(" ")
                .font(.system(size: 11))
        }
    }

    func app(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 24))
            .foregroundStyle(Palette.accent)
            .frame(width: Self.appSize, height: Self.appSize)
            .background(Palette.card.opacity(0.8), in: .rect(cornerRadius: 15))
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

            Text(AmountText.text(record.amount))
                .displayFont(.small, weight: .medium)
                .monospacedDigit()
                .foregroundStyle(Palette.text)
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
                    Text(AmountText.text(amount))
                        .displayFont(.body, weight: .medium)
                        .monospacedDigit()
                        .foregroundStyle(Palette.accentStrong)
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
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .templateCardFace(cornerRadius: Self.tileRadius, shadowRadius: 3)
    }
}
