import Core
@testable import DesignSystem
import SwiftUI
import Testing
import UIKit

@MainActor
struct SnapshotTests {
    @Test
    func render() throws {
        for page in Self.pages {
            let art = try Self.load(page.art)
            let view = StorePage(page: page, art: art)

            try Self.write(view, to: page.file)
        }
    }
}

extension SnapshotTests {
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
        case tap(String, at: UnitPoint)
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
    }

    enum LoadedArt {
        case phone(UIImage)
        case tap(UIImage, at: UnitPoint)
        case inset(UIImage, part: UIImage, corner: CGFloat, width: CGFloat, at: UnitPoint)
        case fan(left: UIImage, center: UIImage, right: UIImage, labels: [String])
        case compare(UIImage, parts: [UIImage], labels: [String])
        case pair(UIImage, UIImage)
    }
}

private struct StorePage: View {
    let page: SnapshotTests.Page
    let art: SnapshotTests.LoadedArt

    var body: some View {
        VStack(spacing: 0) {
            header

            artwork
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(width: 440, height: 956, alignment: .top)
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
    struct Colors {
        let top: Color
        let bottom: Color
        let title: Color
        let note: Color
        let badge: Color
        let badgeText: Color
        let glow: Color
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
        .padding(.top, page.badge == nil ? 72 : 48)
        .frame(height: 300, alignment: .top)
    }

    @ViewBuilder
    var artwork: some View {
        switch art {
        case let .phone(shot):
            phone(shot, width: 360)
        case let .tap(shot, point):
            phone(shot, width: 360)
                .overlay {
                    GeometryReader { proxy in
                        tapMark
                            .position(
                                x: 10 + (proxy.size.width - 20) * point.x,
                                y: 10 + (proxy.size.height - 20) * point.y
                            )
                    }
                }
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
        }
    }

    var tapMark: some View {
        ZStack {
            Circle()
                .fill(colors.badge.opacity(0.18))
                .frame(width: 112, height: 112)

            Circle()
                .stroke(colors.badge.opacity(0.5), lineWidth: 3)
                .frame(width: 84, height: 84)

            Circle()
                .fill(.white.opacity(0.55))
                .frame(width: 52, height: 52)
                .overlay {
                    Circle()
                        .stroke(colors.badge, lineWidth: 3)
                }
        }
    }

    func phone(
        _ shot: UIImage,
        width: CGFloat
    ) -> some View {
        let scale = width / 360

        return Image(uiImage: shot)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .clipShape(.rect(cornerRadius: 44 * scale))
            .padding(10 * scale)
            .background(Color.black, in: .rect(cornerRadius: 54 * scale))
            .shadow(color: colors.glow.opacity(0.35), radius: 24, y: 12)
            .frame(width: width)
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

private extension SnapshotTests {
    static let directory = "__OUT__"

    static let pages = [
        Page(
            file: "1-home",
            badge: "広告なしの家計簿",
            lines: ["今月あといくら？", "が、ひと目で"],
            note: "予算の残りをメーターでお知らせ",
            mood: .cream,
            art: .phone("1-home")
        ),
        Page(
            file: "2-entry",
            badge: nil,
            lines: ["よく使う支出は、", "タップ 1 回"],
            note: "テンプレートと電卓ですばやく記録",
            mood: .blush,
            art: .phone("2-entry")
        ),
        Page(
            file: "3-theme",
            badge: nil,
            lines: ["色もアイコンも、", "自分好みに"],
            note: "ライトとダーク、12 色のテーマを着せ替え",
            mood: .night,
            art: .fan(
                left: "3-theme-rose",
                center: "3-theme-white",
                right: "3-theme-navy",
                labels: ["ローズ", "ホワイト", "ネイビー"]
            )
        ),
        Page(
            file: "4-font",
            badge: "PRO",
            lines: ["文字の雰囲気も、", "選べる"],
            note: "明朝・ゴシック・手書き・ドットなど 6 種類",
            mood: .cream,
            art: .compare(
                "4-font-hand",
                parts: ["3-theme-white", "4-font-hand"],
                labels: ["明朝", "手書き"],
                crop: CGRect(x: 160, y: 560, width: 1000, height: 520)
            )
        ),
        Page(
            file: "5-assets",
            badge: nil,
            lines: ["残高も引き落としも、", "まとめて"],
            note: "口座ごとの残高と、カードの引き落とし日",
            mood: .sage,
            art: .inset(
                "5-assets",
                from: "5-assets",
                crop: CGRect(x: 53, y: 1549, width: 1215, height: 534),
                corner: 20,
                width: 400,
                at: UnitPoint(x: 0.5, y: 0.66)
            )
        ),
        Page(
            file: "6-review",
            badge: nil,
            lines: ["何に使ったか、", "すぐ分かる"],
            note: "カテゴリごとの内訳と前の月との比べ",
            mood: .sand,
            art: .phone("6-review")
        ),
        Page(
            file: "7-records",
            badge: nil,
            lines: ["毎日の支出を、", "カレンダーで"],
            note: "使わなかった日には印がつきます",
            mood: .cream,
            art: .inset(
                "7-records",
                from: "7-records",
                crop: CGRect(x: 69, y: 1270, width: 676, height: 430),
                corner: 20,
                width: 320,
                at: UnitPoint(x: 0.5, y: 0.6)
            )
        ),
        Page(
            file: "8-share",
            badge: "PRO",
            lines: ["家族と、", "ひとつの家計簿を"],
            note: "iCloud で記録をいっしょに",
            mood: .blush,
            art: .pair("7-records", "8-share-rose")
        ),
        Page(
            file: "9-widget",
            badge: nil,
            lines: ["アプリを開かずに、", "すぐ記録"],
            note: "ホーム画面のウィジェットから 1 タップ",
            mood: .sand,
            art: .tap("9-widget", at: UnitPoint(x: 0.85, y: 0.372))
        )
    ]

    static var screenshots: URL {
        URL(fileURLWithPath: directory)
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
        case let .tap(name, point):
            return try .tap(image(name), at: point)
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
        }
    }

    static func write(
        _ view: some View,
        to name: String
    ) throws {
        let renderer = ImageRenderer(content: view)

        renderer.scale = 3
        renderer.isOpaque = true
        renderer.proposedSize = ProposedViewSize(width: 440, height: 956)

        let image = try #require(renderer.cgImage)
        let data = try #require(UIImage(cgImage: image).pngData())
        let url = URL(fileURLWithPath: directory).appending(path: "\(name).png")

        try data.write(to: url)
        try writeSmall(image, to: name)
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
        let folder = URL(fileURLWithPath: directory).appending(path: "6.3")

        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try data.write(to: folder.appending(path: "\(name).png"))
    }
}
