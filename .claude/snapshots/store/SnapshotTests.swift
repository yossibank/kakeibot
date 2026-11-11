import Core
@testable import DesignSystem
import SwiftUI
import Testing
import UIKit

@MainActor
struct SnapshotTests {
    @Test
    func render() throws {
        for (canvas, pages) in Self.pageSets {
            for page in pages {
                let art = try Self.load(page.art)
                let view = StorePage(page: page, art: art, canvas: canvas)

                try Self.write(view, canvas: canvas, to: page.file)
            }
        }

        let shots = try Self.bannerShots.map(Self.image)

        for canvas in [Canvas.header, .search] {
            let view = StoreBanner(shots: shots, canvas: canvas)

            try Self.write(view, canvas: canvas, to: canvas.folder)
        }
    }
}

extension SnapshotTests {
    enum Canvas {
        case phone
        case duoOuter
        case duoInner
        case header
        case search

        var size: CGSize {
            switch self {
            case .phone: CGSize(width: 440, height: 956)
            case .duoOuter: CGSize(width: 466, height: 678)
            case .duoInner: CGSize(width: 951, height: 669)
            case .header: CGSize(width: 1920, height: 823)
            case .search: CGSize(width: 1920, height: 1280)
            }
        }

        var scale: CGFloat {
            switch self {
            case .phone, .duoOuter, .duoInner: 3
            case .header, .search: 2
            }
        }

        var folder: String {
            switch self {
            case .phone: "6.9"
            case .duoOuter: "duo-outer"
            case .duoInner: "duo-inner"
            case .header: "header"
            case .search: "search"
            }
        }

        var headerHeight: CGFloat {
            switch self {
            case .duoOuter, .duoInner: 216
            default: 300
            }
        }

        var artScale: CGFloat {
            switch self {
            case .duoOuter: 0.78
            case .duoInner: 1.6
            default: 1
            }
        }
    }

    struct Page {
        let file: String
        let badge: String?
        let lines: [String]
        let note: String
        let mood: Mood
        let art: Art
    }

    enum Mood {
        case cream
        case blush
        case night
        case sage
        case sand
    }

    enum Art {
        case phone(String)
        case inset(
            String,
            from: String,
            crop: CGRect,
            corner: CGFloat,
            width: CGFloat,
            at: UnitPoint
        )
        case fan(left: String, center: String, right: String, labels: [String])
        case compare(String, parts: [String], labels: [String], crop: CGRect)
        case pair(String, String)
        case receipt(String)
    }

    enum LoadedArt {
        case phone(UIImage)
        case inset(UIImage, part: UIImage, corner: CGFloat, width: CGFloat, at: UnitPoint)
        case fan(left: UIImage, center: UIImage, right: UIImage, labels: [String])
        case compare(UIImage, parts: [UIImage], labels: [String])
        case pair(UIImage, UIImage)
        case receipt(UIImage)
    }
}

private struct StorePage: View {
    let page: SnapshotTests.Page
    let art: SnapshotTests.LoadedArt
    let canvas: SnapshotTests.Canvas

    var body: some View {
        let artHeight = canvas.size.height - canvas.headerHeight

        VStack(spacing: 0) {
            header

            artwork
                .frame(
                    width: Self.designWidth,
                    height: artHeight / canvas.artScale,
                    alignment: .top
                )
                .scaleEffect(canvas.artScale, anchor: .top)
                .frame(width: canvas.size.width, height: artHeight, alignment: .top)
        }
        .frame(width: canvas.size.width, height: canvas.size.height, alignment: .top)
        .background {
            LinearGradient(
                colors: [colors.top, colors.bottom],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .clipped()
        .environment(\.colorScheme, .light)
        .environment(
            \.themeStyle,
            ThemeStyle(
                corner: .standard,
                displayFont: .mincho,
                textFont: .gothic,
                textSize: .standard
            )
        )
    }
}

private extension StorePage {
    struct ReceiptLine {
        let name: String
        let amount: String
    }

    struct Colors {
        let top: Color
        let bottom: Color
        let title: Color
        let note: Color
        let badge: Color
        let badgeText: Color
        let glow: Color
    }

    static let designWidth: CGFloat = 440

    static let receiptLines = [
        ReceiptLine(name: "牛乳", amount: "¥198"),
        ReceiptLine(name: "食パン", amount: "¥168"),
        ReceiptLine(name: "卵", amount: "¥248"),
        ReceiptLine(name: "鶏むね肉", amount: "¥498"),
        ReceiptLine(name: "バナナ", amount: "¥158"),
        ReceiptLine(name: "ヨーグルト×2", amount: "¥276"),
        ReceiptLine(name: "豆腐", amount: "¥98"),
        ReceiptLine(name: "洗剤", amount: "¥456")
    ]

    var topPadding: CGFloat {
        let full: CGFloat = page.badge == nil ? 72 : 48
        return full * canvas.headerHeight / 300
    }

    var colors: Colors {
        switch page.mood {
        case .cream: Colors(
                top: Color(rgb: 0xFBF7EF),
                bottom: Color(rgb: 0xEBDDC4),
                title: Color(rgb: 0x5A3A12),
                note: Color(rgb: 0x8A7357),
                badge: Color(rgb: 0x9A6A2A),
                badgeText: Color(rgb: 0xFBF7EF),
                glow: Color(rgb: 0x9A6A2A)
            )

        case .blush: Colors(
                top: Color(rgb: 0xFCF3F1),
                bottom: Color(rgb: 0xEFD3D1),
                title: Color(rgb: 0x7A3442),
                note: Color(rgb: 0x9A6670),
                badge: Color(rgb: 0x9C4A5A),
                badgeText: Color(rgb: 0xFCF3F1),
                glow: Color(rgb: 0x9C4A5A)
            )

        case .night: Colors(
                top: Color(rgb: 0x1B2236),
                bottom: Color(rgb: 0x0C1020),
                title: Color(rgb: 0xF3DFB4),
                note: Color(rgb: 0xB8B3A6),
                badge: Color(rgb: 0xE0B66A),
                badgeText: Color(rgb: 0x1B2236),
                glow: Color(rgb: 0xE0B66A)
            )

        case .sage: Colors(
                top: Color(rgb: 0xF4F6EF),
                bottom: Color(rgb: 0xD7DFCB),
                title: Color(rgb: 0x34492E),
                note: Color(rgb: 0x6A7A62),
                badge: Color(rgb: 0x4F6B45),
                badgeText: Color(rgb: 0xF4F6EF),
                glow: Color(rgb: 0x4F6B45)
            )

        case .sand: Colors(
                top: Color(rgb: 0xF8F1E4),
                bottom: Color(rgb: 0xE6CFA6),
                title: Color(rgb: 0x5E3F12),
                note: Color(rgb: 0x8C7048),
                badge: Color(rgb: 0xA8741E),
                badgeText: Color(rgb: 0xF8F1E4),
                glow: Color(rgb: 0xA8741E)
            )
        }
    }

    var header: some View {
        VStack(spacing: 16) {
            if let badge = page.badge {
                Text(badge)
                    .textFont(size: .body, weight: .semibold)
                    .tracking(2)
                    .foregroundStyle(colors.badgeText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(colors.badge, in: .capsule)
            }

            VStack(spacing: 4) {
                ForEach(page.lines, id: \.self) { line in
                    Text(line)
                        .displayFont(.display, weight: .bold)
                        .foregroundStyle(colors.title)
                }
            }

            Text(page.note)
                .textFont(size: .body)
                .foregroundStyle(colors.note)
        }
        .padding(.top, topPadding)
        .frame(height: canvas.headerHeight, alignment: .top)
    }

    @ViewBuilder
    var artwork: some View {
        switch art {
        case let .phone(shot):
            phone(shot, width: 360)

        case let .inset(shot, part, corner, width, point):
            ZStack(alignment: .top) {
                phone(shot, width: 360)

                GeometryReader { proxy in
                    Image(uiImage: part)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(.rect(cornerRadius: corner))
                        .frame(width: width)
                        .shadow(color: .black.opacity(0.22), radius: 20, y: 12)
                        .position(
                            x: proxy.size.width * point.x,
                            y: proxy.size.height * point.y
                        )
                }
            }

        case let .fan(left, center, right, labels):
            fan(
                [left, center, right],
                labels: labels
            )

        case let .compare(base, parts, labels):
            compare(base, parts: parts, labels: labels)

        case let .pair(left, right):
            ZStack(alignment: .top) {
                phone(left, width: 260)
                    .rotationEffect(.degrees(-6))
                    .offset(x: -88, y: 28)

                phone(right, width: 260)
                    .rotationEffect(.degrees(6))
                    .offset(x: 88, y: 28)

                Image(systemName: "link")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(colors.badgeText)
                    .frame(width: 72, height: 72)
                    .background(colors.badge, in: .circle)
                    .overlay {
                        Circle()
                            .stroke(colors.badgeText, lineWidth: 4)
                    }
                    .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
                    .offset(y: 220)
            }

        case let .receipt(shot):
            ZStack(alignment: .topLeading) {
                phone(shot, width: 300)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 20)
                    .offset(y: 120)

                scannedReceipt
                    .rotationEffect(.degrees(-6))
                    .offset(x: 32, y: 4)
            }
        }
    }

    var scannedReceipt: some View {
        VStack(spacing: 6) {
            Text("スーパー青葉")
                .textFont(size: .small, weight: .semibold)

            Text("2026/11/10 18:24")
                .textFont(size: .micro)
                .foregroundStyle(Color(rgb: 0x8A8A8A))

            receiptRule

            ForEach(Self.receiptLines, id: \.name) { line in
                HStack {
                    Text(line.name)

                    Spacer(minLength: 4)

                    Text(line.amount)
                        .monospacedDigit()
                }
                .textFont(size: .micro)
            }

            receiptRule

            HStack {
                Text("合計")

                Spacer(minLength: 4)

                Text("¥2,100")
                    .monospacedDigit()
            }
            .textFont(size: .small, weight: .bold)
        }
        .foregroundStyle(Color(rgb: 0x333333))
        .padding(.horizontal, 12)
        .padding(.top, 16)
        .padding(.bottom, 24)
        .frame(width: 164)
        .background(.white, in: ReceiptPaper())
        .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
        .padding(16)
        .overlay {
            ViewfinderCorners()
                .stroke(colors.badge, style: StrokeStyle(lineWidth: 4, lineCap: .round))
        }
        .overlay(alignment: .topLeading) {
            Image(systemName: "camera.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(colors.badgeText)
                .frame(width: 52, height: 52)
                .background(colors.badge, in: .circle)
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                .offset(x: -16, y: -16)
        }
    }

    var receiptRule: some View {
        Line()
            .stroke(Color(rgb: 0xBBBBBB), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            .frame(height: 1)
    }

    func phone(
        _ shot: UIImage,
        width: CGFloat
    ) -> some View {
        PhoneFrame(shot: shot, width: width)
            .shadow(color: colors.glow.opacity(0.35), radius: 24, y: 12)
    }

    func fan(
        _ shots: [UIImage],
        labels: [String]
    ) -> some View {
        ZStack(alignment: .top) {
            phone(shots[0], width: 220)
                .rotationEffect(.degrees(-8), anchor: .bottom)
                .offset(x: -100, y: 72)

            phone(shots[2], width: 220)
                .rotationEffect(.degrees(8), anchor: .bottom)
                .offset(x: 100, y: 72)

            phone(shots[1], width: 260)
                .offset(y: 36)

            HStack(spacing: 12) {
                ForEach(labels, id: \.self) { label in
                    Text(label)
                        .textFont(size: .small, weight: .semibold)
                        .foregroundStyle(colors.title)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(colors.title.opacity(0.12), in: .capsule)
                }
            }
            .offset(y: -12)
        }
    }

    func compare(
        _ base: UIImage,
        parts: [UIImage],
        labels: [String]
    ) -> some View {
        ZStack(alignment: .top) {
            phone(base, width: 340)
                .opacity(0.9)
                .offset(x: 40)

            VStack(spacing: 20) {
                ForEach(Array(zip(parts, labels)), id: \.1) { part, label in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(label)
                            .textFont(size: .body, weight: .semibold)
                            .foregroundStyle(colors.badgeText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                            .background(colors.badge, in: .capsule)

                        Image(uiImage: part)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(.rect(cornerRadius: 20))
                            .frame(width: 300)
                            .shadow(color: .black.opacity(0.18), radius: 16, y: 8)
                    }
                }
            }
            .offset(x: -40, y: 40)
        }
    }
}

private struct StoreBanner: View {
    let shots: [UIImage]
    let canvas: SnapshotTests.Canvas

    var body: some View {
        let zoom = canvas.size.width / Self.designWidth
        let height = canvas.size.height / zoom

        HStack(spacing: 40) {
            VStack(alignment: .leading, spacing: 16) {
                Text("広告なしの家計簿")
                    .textFont(size: .body, weight: .semibold)
                    .tracking(2)
                    .foregroundStyle(Color(rgb: 0xFBF7EF))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color(rgb: 0x9A6A2A), in: .capsule)

                VStack(alignment: .leading, spacing: 4) {
                    Text("今月あといくら？")
                    Text("が、ひと目で")
                }
                .displayFont(.display, weight: .bold)
                .foregroundStyle(Color(rgb: 0x5A3A12))

                Text("レシートを撮れば、品目まで入る")
                    .textFont(size: .body)
                    .foregroundStyle(Color(rgb: 0x8A7357))
            }
            .fixedSize()

            phones(height: height)
        }
        .frame(width: Self.designWidth, height: height)
        .background {
            LinearGradient(
                colors: [Color(rgb: 0xFBF7EF), Color(rgb: 0xEBDDC4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .clipped()
        .scaleEffect(zoom, anchor: .topLeading)
        .frame(width: canvas.size.width, height: canvas.size.height, alignment: .topLeading)
        .environment(\.colorScheme, .light)
        .environment(
            \.themeStyle,
            ThemeStyle(
                corner: .standard,
                displayFont: .mincho,
                textFont: .gothic,
                textSize: .standard
            )
        )
    }
}

private extension StoreBanner {
    static let designWidth: CGFloat = 800
}

private extension StoreBanner {
    func phones(height: CGFloat) -> some View {
        let limit: CGFloat = canvas == .header ? 150 : 180
        let width = min(height * 0.52, limit)

        return ZStack(alignment: .top) {
            phone(shots[1], width: width * 0.86)
                .rotationEffect(.degrees(-8), anchor: .bottom)
                .offset(x: -width * 0.62, y: height * 0.2)

            phone(shots[2], width: width * 0.86)
                .rotationEffect(.degrees(8), anchor: .bottom)
                .offset(x: width * 0.62, y: height * 0.2)

            phone(shots[0], width: width)
                .offset(y: height * 0.1)
        }
        .frame(width: width * 2.2, height: height, alignment: .top)
    }

    func phone(
        _ shot: UIImage,
        width: CGFloat
    ) -> some View {
        PhoneFrame(shot: shot, width: width)
            .shadow(color: Color(rgb: 0x9A6A2A).opacity(0.3), radius: 16, y: 8)
    }
}

private struct PhoneFrame: View {
    let shot: UIImage
    let width: CGFloat

    var body: some View {
        let height = width * shot.size.height / shot.size.width
        let scale = min(width, height) / 360

        Image(uiImage: shot)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .clipShape(.rect(cornerRadius: 44 * scale))
            .padding(10 * scale)
            .background(Color.black, in: .rect(cornerRadius: 54 * scale))
            .frame(width: width)
    }
}

private struct ReceiptPaper: Shape {
    func path(in rect: CGRect) -> Path {
        let tooth: CGFloat = 8
        let count = Int(rect.width / tooth)
        let step = rect.width / CGFloat(count)
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))

        for index in 0..<count {
            let x = rect.maxX - step * CGFloat(index)

            path.addLine(to: CGPoint(x: x - step / 2, y: rect.maxY - tooth / 2))
            path.addLine(to: CGPoint(x: x - step, y: rect.maxY))
        }

        path.closeSubpath()

        return path
    }
}

private struct ViewfinderCorners: Shape {
    func path(in rect: CGRect) -> Path {
        let length: CGFloat = 28
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.minY + length))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + length, y: rect.minY))

        path.move(to: CGPoint(x: rect.maxX - length, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + length))

        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - length))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - length, y: rect.maxY))

        path.move(to: CGPoint(x: rect.minX + length, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - length))

        return path
    }
}

private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))

        return path
    }
}

private extension SnapshotTests {
    static let directory = "__OUT__"
    static let bannerShots = ["01-home", "03-receipt", "07-review"]

    static let outerPages = [
        Page(
            file: "01-home",
            badge: "広告なしの家計簿",
            lines: ["今月あといくら？", "が、ひと目で"],
            note: "予算の残りをメーターでお知らせ",
            mood: .cream,
            art: .phone("outer-01-home")
        ),
        Page(
            file: "02-entry",
            badge: nil,
            lines: ["よく使う支出は、", "タップ 1 回"],
            note: "テンプレートと電卓ですばやく記録",
            mood: .blush,
            art: .phone("outer-02-entry")
        ),
        Page(
            file: "03-receipt",
            badge: nil,
            lines: ["レシートを撮れば、", "品目まで入る"],
            note: "品名・合計・日付・店名を読み取り",
            mood: .sage,
            art: .receipt("outer-03-receipt")
        ),
        Page(
            file: "04-theme",
            badge: nil,
            lines: ["色もアイコンも、", "自分好みに"],
            note: "ライトとダーク、12 色のテーマを着せ替え",
            mood: .night,
            art: .fan(
                left: "outer-04-theme-rose",
                center: "outer-01-home",
                right: "outer-04-theme-navy",
                labels: ["ローズ", "ホワイト", "ネイビー"]
            )
        ),
        Page(
            file: "05-font",
            badge: "PRO",
            lines: ["文字の雰囲気も、", "選べる"],
            note: "明朝・ゴシック・手書き・ドットなど 6 種類",
            mood: .cream,
            art: .compare(
                "outer-05-font-hand",
                parts: ["outer-01-home", "outer-05-font-hand"],
                labels: ["明朝", "手書き"],
                crop: CGRect(x: 52, y: 200, width: 1040, height: 560)
            )
        ),
        Page(
            file: "06-assets",
            badge: nil,
            lines: ["残高も引き落としも、", "まとめて"],
            note: "口座ごとの残高と、カードの引き落とし日",
            mood: .sand,
            art: .phone("outer-06-assets")
        ),
        Page(
            file: "07-review",
            badge: nil,
            lines: ["何に使ったか、", "すぐ分かる"],
            note: "カテゴリごとの内訳と前の月との比べ",
            mood: .sage,
            art: .phone("outer-07-review")
        ),
        Page(
            file: "08-records",
            badge: nil,
            lines: ["毎日の支出を、", "カレンダーで"],
            note: "使わなかった日には印がつきます",
            mood: .cream,
            art: .phone("outer-08-records")
        )
    ]

    static let pages = [
        Page(
            file: "01-home",
            badge: "広告なしの家計簿",
            lines: ["今月あといくら？", "が、ひと目で"],
            note: "予算の残りをメーターでお知らせ",
            mood: .cream,
            art: .phone("01-home")
        ),
        Page(
            file: "02-entry",
            badge: nil,
            lines: ["よく使う支出は、", "タップ 1 回"],
            note: "テンプレートと電卓ですばやく記録",
            mood: .blush,
            art: .phone("02-entry")
        ),
        Page(
            file: "03-receipt",
            badge: nil,
            lines: ["レシートを撮れば、", "品目まで入る"],
            note: "品名・合計・日付・店名を読み取り",
            mood: .sage,
            art: .receipt("03-receipt")
        ),
        Page(
            file: "04-theme",
            badge: nil,
            lines: ["色もアイコンも、", "自分好みに"],
            note: "ライトとダーク、12 色のテーマを着せ替え",
            mood: .night,
            art: .fan(
                left: "04-theme-rose",
                center: "04-theme-white",
                right: "04-theme-navy",
                labels: ["ローズ", "ホワイト", "ネイビー"]
            )
        ),
        Page(
            file: "05-font",
            badge: "PRO",
            lines: ["文字の雰囲気も、", "選べる"],
            note: "明朝・ゴシック・手書き・ドットなど 6 種類",
            mood: .cream,
            art: .compare(
                "05-font-hand",
                parts: ["04-theme-white", "05-font-hand"],
                labels: ["明朝", "手書き"],
                crop: CGRect(x: 160, y: 560, width: 1000, height: 520)
            )
        ),
        Page(
            file: "06-assets",
            badge: nil,
            lines: ["残高も引き落としも、", "まとめて"],
            note: "口座ごとの残高と、カードの引き落とし日",
            mood: .sand,
            art: .inset(
                "06-assets",
                from: "06-assets",
                crop: CGRect(x: 53, y: 1981, width: 1215, height: 534),
                corner: 20,
                width: 400,
                at: UnitPoint(x: 0.5, y: 0.66)
            )
        ),
        Page(
            file: "07-review",
            badge: nil,
            lines: ["何に使ったか、", "すぐ分かる"],
            note: "カテゴリごとの内訳と前の月との比べ",
            mood: .sage,
            art: .phone("07-review")
        ),
        Page(
            file: "08-records",
            badge: nil,
            lines: ["毎日の支出を、", "カレンダーで"],
            note: "使わなかった日には印がつきます",
            mood: .cream,
            art: .inset(
                "08-records",
                from: "08-records",
                crop: CGRect(x: 69, y: 1725, width: 676, height: 400),
                corner: 20,
                width: 320,
                at: UnitPoint(x: 0.5, y: 0.6)
            )
        ),
        Page(
            file: "09-share",
            badge: "PRO",
            lines: ["家族と、", "ひとつの家計簿を"],
            note: "iCloud で記録をいっしょに",
            mood: .blush,
            art: .pair("08-records", "09-share-rose")
        ),
        Page(
            file: "10-outlook",
            badge: "NEW",
            lines: ["月末にいくら残る？", "が、先に分かる"],
            note: "固定費と予定の記録から、月末の残りを見込み",
            mood: .sand,
            art: .phone("10-outlook")
        )
    ]

    static let innerPages = [
        Page(
            file: "01-home",
            badge: nil,
            lines: ["広い画面で、", "家計をひと目で"],
            note: "左のサイドバーから、すぐに切り替え",
            mood: .cream,
            art: .phone("inner-01-home")
        ),
        Page(
            file: "02-review",
            badge: nil,
            lines: ["何に使ったか、", "並べて分かる"],
            note: "内訳と前の月との比べを 2 列で",
            mood: .sage,
            art: .phone("inner-02-review")
        ),
        Page(
            file: "03-assets",
            badge: nil,
            lines: ["残高も引き落としも、", "まとめて"],
            note: "口座ごとの残高と、カードの引き落とし日",
            mood: .sand,
            art: .phone("inner-03-assets")
        ),
        Page(
            file: "04-records",
            badge: nil,
            lines: ["毎日の支出を、", "カレンダーで"],
            note: "使わなかった日には印がつきます",
            mood: .blush,
            art: .phone("inner-04-records")
        ),
        Page(
            file: "05-entry",
            badge: nil,
            lines: ["よく使う支出は、", "タップ 1 回"],
            note: "テンプレートと電卓ですばやく記録",
            mood: .cream,
            art: .phone("inner-05-entry")
        )
    ]

    static var pageSets: [(Canvas, [Page])] {
        [
            (.phone, pages),
            (.duoOuter, outerPages),
            (.duoInner, innerPages)
        ]
    }

    static var screenshots: URL {
        URL(fileURLWithPath: directory)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "store/screenshots/raw")
    }

    static func image(_ name: String) throws -> UIImage {
        let path = screenshots.appending(path: "\(name).png").path()
        return try #require(UIImage(contentsOfFile: path))
    }

    static func load(_ art: Art) throws -> LoadedArt {
        switch art {
        case let .phone(name):
            return try .phone(image(name))

        case let .inset(name, source, crop, corner, width, point):
            let cropped = try #require(image(source).cgImage?.cropping(to: crop))

            return try .inset(
                image(name),
                part: UIImage(cgImage: cropped),
                corner: corner,
                width: width,
                at: point
            )

        case let .fan(left, center, right, labels):
            return try .fan(
                left: image(left),
                center: image(center),
                right: image(right),
                labels: labels
            )

        case let .compare(base, parts, labels, crop):
            let cropped = try parts.map { name in
                let part = try #require(image(name).cgImage?.cropping(to: crop))
                return UIImage(cgImage: part)
            }

            return try .compare(image(base), parts: cropped, labels: labels)

        case let .pair(left, right):
            return try .pair(image(left), image(right))

        case let .receipt(name):
            return try .receipt(image(name))
        }
    }

    static func write(
        _ view: some View,
        canvas: Canvas,
        to name: String
    ) throws {
        let renderer = ImageRenderer(content: view)

        renderer.scale = canvas.scale
        renderer.isOpaque = true
        renderer.proposedSize = ProposedViewSize(canvas.size)

        let image = try #require(renderer.cgImage)
        let data = try #require(UIImage(cgImage: image).pngData())

        try data.write(to: output(canvas.folder, name))

        if canvas == .phone {
            try writeSmall(image, to: name)
        }
    }

    static func writeSmall(
        _ image: CGImage,
        to name: String
    ) throws {
        let context = try #require(
            CGContext(
                data: nil,
                width: 1206,
                height: 2622,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            )
        )

        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: 1206, height: 2622))

        let small = try #require(context.makeImage())
        let data = try #require(UIImage(cgImage: small).pngData())

        try data.write(to: output("6.3", name))
    }

    static func output(
        _ folder: String,
        _ name: String
    ) -> URL {
        URL(fileURLWithPath: directory).appending(path: "\(folder)_\(name).png")
    }
}
