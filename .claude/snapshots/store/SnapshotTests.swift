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

        for (index, shot) in Self.shots.enumerated() {
            let images = try shot.phones.map { try Self.image($0.name) }
            let view = PanoramaPage(shot: shot, index: index, images: images)

            try Self.write(view, canvas: .phone, to: shot.file)
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
        let lines: [String]
        let lead: Lead
        let art: Art
    }

    enum Art {
        case phone(String)
        case fan(left: String, center: String, right: String, labels: [String])
        case compare(String, parts: [String], labels: [String], crop: CGRect)
        case receipt(String)
    }

    enum LoadedArt {
        case phone(UIImage)
        case fan(left: UIImage, center: UIImage, right: UIImage, labels: [String])
        case compare(UIImage, parts: [UIImage], labels: [String])
        case receipt(UIImage)
    }

    struct Shot {
        let file: String
        let lines: [String]
        let lead: Lead
        let phones: [Phone]
    }

    enum Lead {
        case free
        case note(String)
    }

    struct Phone {
        let name: String
        let x: CGFloat
        let y: CGFloat
        let width: CGFloat
        let angle: Double
        var anchor: UnitPoint = .center
    }
}

private struct PanoramaPage: View {
    let shot: SnapshotTests.Shot
    let index: Int
    let images: [UIImage]

    var body: some View {
        let canvas = SnapshotTests.Canvas.phone
        let zoom = canvas.size.width / Self.designWidth

        ZStack(alignment: .topLeading) {
            StoreRings(rings: Self.rings, shift: Self.pitch * CGFloat(index))

            ForEach(Array(zip(shot.phones, images).enumerated()), id: \.offset) { _, pair in
                phone(pair.0, image: pair.1)
            }

            StoreHeadline(lines: shot.lines, lead: shot.lead, scale: 1)
                .offset(x: 24, y: 44)
        }
        .frame(
            width: Self.designWidth,
            height: canvas.size.height / zoom,
            alignment: .topLeading
        )
        .background(StoreInk.ground)
        .clipped()
        .scaleEffect(zoom, anchor: .topLeading)
        .frame(width: canvas.size.width, height: canvas.size.height, alignment: .topLeading)
        .environment(\.colorScheme, .light)
    }
}

private extension PanoramaPage {
    static let designWidth: CGFloat = 320
    static let pitch: CGFloat = 336

    static let rings = [
        StoreRings.Ring(
            x: 496,
            y: 900,
            radius: 640,
            paint: .stroke(opacity: 0.7, width: 2, dash: [])
        ),
        StoreRings.Ring(
            x: 496,
            y: 900,
            radius: 600,
            paint: .stroke(opacity: 0.3, width: 1, dash: [2, 14])
        ),
        StoreRings.Ring(
            x: 496,
            y: 900,
            radius: 690,
            paint: .stroke(opacity: 0.18, width: 1, dash: [])
        ),
        StoreRings.Ring(
            x: 1340,
            y: 680,
            radius: 250,
            paint: .stroke(opacity: 0.4, width: 2, dash: [])
        ),
        StoreRings.Ring(
            x: 2016,
            y: 660,
            radius: 320,
            paint: .stroke(opacity: 0.55, width: 2, dash: [])
        ),
        StoreRings.Ring(
            x: 2016,
            y: 660,
            radius: 290,
            paint: .stroke(opacity: 0.25, width: 1, dash: [2, 14])
        ),
        StoreRings.Ring(x: 2900, y: 620, radius: 210, paint: .fill(Color(rgb: 0xF4E9E4)))
    ]

    func phone(
        _ phone: SnapshotTests.Phone,
        image: UIImage
    ) -> some View {
        PhoneFrame(shot: image, width: phone.width)
            .shadow(color: .black.opacity(0.5), radius: 30, y: 30)
            .rotationEffect(.degrees(phone.angle), anchor: phone.anchor)
            .offset(x: phone.x, y: phone.y)
    }
}

private enum StoreInk {
    static let ground = Color(rgb: 0x131A30)
    static let accent = Color(rgb: 0xE3C58A)
    static let title = Color(rgb: 0xF6EAD2)
    static let note = Color(rgb: 0xC9CFE0)
}

private struct StoreRings: View {
    let rings: [Ring]
    var shift: CGFloat = 0

    var body: some View {
        Canvas { context, _ in
            for ring in rings {
                let rect = CGRect(
                    x: ring.x - shift - ring.radius,
                    y: ring.y - ring.radius,
                    width: ring.radius * 2,
                    height: ring.radius * 2
                )
                let path = Path(ellipseIn: rect)

                switch ring.paint {
                case let .stroke(opacity, width, dash):
                    context.stroke(
                        path,
                        with: .color(StoreInk.accent.opacity(opacity)),
                        style: StrokeStyle(lineWidth: width, dash: dash)
                    )

                case let .fill(color):
                    context.fill(path, with: .color(color))
                }
            }
        }
    }
}

extension StoreRings {
    enum Paint {
        case stroke(opacity: Double, width: CGFloat, dash: [CGFloat])
        case fill(Color)
    }

    struct Ring {
        let x: CGFloat
        let y: CGFloat
        let radius: CGFloat
        let paint: Paint
    }

    static func arcs(
        x: CGFloat,
        y: CGFloat,
        radius: CGFloat
    ) -> [Ring] {
        [
            Ring(x: x, y: y, radius: radius, paint: .stroke(opacity: 0.7, width: 2, dash: [])),
            Ring(
                x: x,
                y: y,
                radius: radius * 0.94,
                paint: .stroke(opacity: 0.3, width: 1, dash: [2, 14])
            ),
            Ring(
                x: x,
                y: y,
                radius: radius * 1.08,
                paint: .stroke(opacity: 0.18, width: 1, dash: [])
            )
        ]
    }
}

private struct StoreHeadline: View {
    let lines: [String]
    let lead: SnapshotTests.Lead
    let scale: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 10 * scale) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .font(.display(size: 44 * scale, weight: .bold, in: .mincho))
                        .foregroundStyle(StoreInk.title)
                        .frame(height: 50.6 * scale, alignment: .leading)
                }
            }

            switch lead {
            case .free:
                freeBand

            case let .note(note):
                Text(note)
                    .font(.system(size: 16 * scale, weight: .medium))
                    .foregroundStyle(StoreInk.note)
                    .fixedSize()
            }
        }
    }
}

private extension StoreHeadline {
    var freeBand: some View {
        HStack(spacing: 10 * scale) {
            Text("無料")

            Circle()
                .fill(StoreInk.accent)
                .frame(width: 4 * scale, height: 4 * scale)

            Text("広告なし")
        }
        .font(.display(size: 19 * scale, weight: .bold, in: .mincho))
        .tracking(2.6 * scale)
        .foregroundStyle(StoreInk.accent)
        .padding(.horizontal, 12 * scale)
        .padding(.vertical, 5 * scale)
        .overlay(alignment: .top) {
            StoreInk.accent
                .frame(height: 1)
        }
        .overlay(alignment: .bottom) {
            StoreInk.accent
                .frame(height: 1)
        }
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
            StoreRings(rings: rings)
        }
        .background(StoreInk.ground)
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

    var rings: [StoreRings.Ring] {
        let size = canvas.size

        return StoreRings.arcs(
            x: size.width * 1.1,
            y: size.height * 1.15,
            radius: max(size.width, size.height) * 0.85
        )
    }

    var header: some View {
        StoreHeadline(lines: page.lines, lead: page.lead, scale: 1.15)
            .padding(.leading, 28)
            .padding(.top, 30)
            .frame(
                width: canvas.size.width,
                height: canvas.headerHeight,
                alignment: .topLeading
            )
    }

    @ViewBuilder
    var artwork: some View {
        switch art {
        case let .phone(shot):
            phone(shot, width: 360)

        case let .fan(left, center, right, labels):
            fan(
                [left, center, right],
                labels: labels
            )

        case let .compare(base, parts, labels):
            compare(base, parts: parts, labels: labels)

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
                .stroke(StoreInk.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
        }
        .overlay(alignment: .topLeading) {
            Image(systemName: "camera.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(StoreInk.ground)
                .frame(width: 52, height: 52)
                .background(StoreInk.accent, in: .circle)
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
            .shadow(color: .black.opacity(0.5), radius: 24, y: 16)
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
                        .foregroundStyle(StoreInk.title)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(StoreInk.accent.opacity(0.2), in: .capsule)
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
                            .foregroundStyle(StoreInk.ground)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                            .background(StoreInk.accent, in: .capsule)

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
            VStack(alignment: .leading, spacing: 14) {
                StoreHeadline(lines: ["好きな色で、", "続く家計簿。"], lead: .free, scale: 1.15)

                Text("色も字体も、着せ替え")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(StoreInk.note)
            }
            .fixedSize()

            phones(height: height)
        }
        .frame(width: Self.designWidth, height: height)
        .background {
            StoreRings(rings: rings(height: height))
        }
        .background(StoreInk.ground)
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
            .shadow(color: .black.opacity(0.5), radius: 20, y: 14)
    }

    func rings(height: CGFloat) -> [StoreRings.Ring] {
        let width = Self.designWidth
        let radius = (pow(width * 0.67, 2) + pow(height * 1.05, 2)).squareRoot()

        return StoreRings.arcs(
            x: width * 1.25,
            y: height * 2.05,
            radius: radius
        )
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
    static let bannerShots = ["04-theme-navy", "04-theme-rose", "04-theme-sage"]

    static let outerPages = [
        Page(
            file: "01-home",
            lines: ["今月あと", "いくら？"],
            lead: .free,
            art: .phone("outer-01-home")
        ),
        Page(
            file: "02-theme",
            lines: ["色も、", "着せ替え。"],
            lead: .note("ライトとダークの 12 色から選べます"),
            art: .fan(
                left: "outer-04-theme-rose",
                center: "outer-01-home",
                right: "outer-04-theme-navy",
                labels: ["ローズ", "ホワイト", "ネイビー"]
            )
        ),
        Page(
            file: "03-entry",
            lines: ["記録は、", "タップ 1 回"],
            lead: .note("テンプレートと電卓ですばやく"),
            art: .phone("outer-02-entry")
        ),
        Page(
            file: "04-receipt",
            lines: ["レシートを", "撮れば入る"],
            lead: .note("品名・合計・日付を読み取り"),
            art: .receipt("outer-03-receipt")
        ),
        Page(
            file: "05-font",
            lines: ["字体も、", "選べる"],
            lead: .note("手書きやドットなど 6 種類"),
            art: .compare(
                "outer-05-font-hand",
                parts: ["outer-01-home", "outer-05-font-hand"],
                labels: ["明朝", "手書き"],
                crop: CGRect(x: 52, y: 200, width: 1040, height: 560)
            )
        ),
        Page(
            file: "06-assets",
            lines: ["残高も、", "引き落としも"],
            lead: .note("口座とカードをまとめて"),
            art: .phone("outer-06-assets")
        ),
        Page(
            file: "07-review",
            lines: ["何に使ったか", "すぐ分かる"],
            lead: .note("内訳と前の月との比べ"),
            art: .phone("outer-07-review")
        ),
        Page(
            file: "08-records",
            lines: ["毎日の支出を", "カレンダーで"],
            lead: .note("使わなかった日には印がつきます"),
            art: .phone("outer-08-records")
        )
    ]

    static let shots = [
        Shot(
            file: "01-home",
            lines: ["今月あと", "いくら？"],
            lead: .free,
            phones: [
                Phone(name: "04-theme-navy", x: 34, y: 200, width: 270, angle: -3)
            ]
        ),
        Shot(
            file: "02-theme",
            lines: ["色も、", "着せ替え。"],
            lead: .note("ライトとダークの 12 色から選べます"),
            phones: [
                Phone(
                    name: "04-theme-ivory",
                    x: 16,
                    y: 238,
                    width: 210,
                    angle: -10,
                    anchor: .bottom
                ),
                Phone(
                    name: "04-theme-sage",
                    x: 94,
                    y: 238,
                    width: 210,
                    angle: 10,
                    anchor: .bottom
                ),
                Phone(name: "04-theme-rose", x: 40, y: 200, width: 240, angle: 0)
            ]
        ),
        Shot(
            file: "03-entry",
            lines: ["記録は、", "タップ 1 回"],
            lead: .note("テンプレートと電卓ですばやく"),
            phones: [
                Phone(name: "02-entry-black", x: 30, y: 200, width: 270, angle: 3)
            ]
        ),
        Shot(
            file: "04-font",
            lines: ["字体も、", "選べる"],
            lead: .note("手書きやドットなど 6 種類"),
            phones: [
                Phone(name: "05-font-hand", x: 12, y: 196, width: 250, angle: -4),
                Phone(name: "05-font-text", x: 132, y: 270, width: 220, angle: 5)
            ]
        ),
        Shot(
            file: "05-backdrop",
            lines: ["背景も、", "和紙や方眼に"],
            lead: .note("角の丸みや行の間隔まで"),
            phones: [
                Phone(name: "05-look-backdrop", x: 20, y: 196, width: 280, angle: 2)
            ]
        ),
        Shot(
            file: "06-receipt",
            lines: ["レシートを", "撮れば入る"],
            lead: .note("品名・合計・日付を読み取り"),
            phones: [
                Phone(name: "03-receipt", x: 20, y: 196, width: 280, angle: -2)
            ]
        ),
        Shot(
            file: "07-share",
            lines: ["ふたりで、", "ひとつの家計"],
            lead: .note("共有の財布をいっしょに"),
            phones: [
                Phone(name: "09-share-rose", x: 20, y: 196, width: 280, angle: 2)
            ]
        ),
        Shot(
            file: "08-review",
            lines: ["何に使ったか", "すぐ分かる"],
            lead: .note("内訳と前の月との比べ"),
            phones: [
                Phone(name: "07-review-black", x: 20, y: 196, width: 280, angle: -2)
            ]
        ),
        Shot(
            file: "09-outlook",
            lines: ["月末の残りが", "先に分かる"],
            lead: .note("固定費と予定から見込みます"),
            phones: [
                Phone(name: "10-outlook", x: 20, y: 196, width: 280, angle: 2)
            ]
        ),
        Shot(
            file: "10-assets",
            lines: ["残高も、", "引き落としも"],
            lead: .note("口座とカードをまとめて"),
            phones: [
                Phone(name: "06-assets-black", x: 20, y: 196, width: 280, angle: -2)
            ]
        )
    ]

    static let innerPages = [
        Page(
            file: "01-home",
            lines: ["広い画面で、", "家計をひと目で"],
            lead: .free,
            art: .phone("inner-01-home")
        ),
        Page(
            file: "02-review",
            lines: ["何に使ったか、", "並べて分かる"],
            lead: .note("内訳と前の月との比べを 2 列で"),
            art: .phone("inner-02-review")
        ),
        Page(
            file: "03-assets",
            lines: ["残高も引き落としも、", "まとめて"],
            lead: .note("口座ごとの残高と、カードの引き落とし日"),
            art: .phone("inner-03-assets")
        ),
        Page(
            file: "04-records",
            lines: ["毎日の支出を、", "カレンダーで"],
            lead: .note("使わなかった日には印がつきます"),
            art: .phone("inner-04-records")
        ),
        Page(
            file: "05-entry",
            lines: ["よく使う支出は、", "タップ 1 回"],
            lead: .note("テンプレートと電卓ですばやく記録"),
            art: .phone("inner-05-entry")
        )
    ]

    static var pageSets: [(Canvas, [Page])] {
        [
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
