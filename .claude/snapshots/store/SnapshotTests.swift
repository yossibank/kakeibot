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
            let path = Self.screenshots.appending(path: "\(page.file).png").path()
            let shot = try #require(UIImage(contentsOfFile: path))
            let view = StorePage(page: page, shot: shot)

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
    }
}

private struct StorePage: View {
    let page: SnapshotTests.Page
    let shot: UIImage

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                if let badge = page.badge {
                    Text(badge)
                        .textFont(size: .body, weight: .semibold)
                        .tracking(2)
                        .foregroundStyle(Palette.backgroundTop)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Palette.accent, in: .capsule)
                }

                VStack(spacing: 4) {
                    ForEach(page.lines, id: \.self) { line in
                        Text(line)
                            .displayFont(.display, weight: .bold)
                            .foregroundStyle(Palette.accentStrong)
                    }
                }

                Text(page.note)
                    .textFont(size: .body)
                    .foregroundStyle(Palette.subtext)
            }
            .padding(.top, page.badge == nil ? 72 : 48)
            .frame(height: 300, alignment: .top)

            Image(uiImage: shot)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(.rect(cornerRadius: 44))
                .padding(10)
                .background(Color.black, in: .rect(cornerRadius: 54))
                .shadow(color: Palette.accent.opacity(.medium), radius: 24, y: 12)
                .frame(width: 360)
        }
        .frame(width: 440, height: 956, alignment: .top)
        .background {
            LinearGradient(
                colors: [Palette.backgroundTop, Palette.accent.opacity(.soft)],
                startPoint: .top,
                endPoint: .bottom
            )
            .background(Palette.backgroundTop)
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

private extension SnapshotTests {
    static let directory = "__OUT__"

    static let pages = [
        Page(
            file: "1-home",
            badge: "広告なしの家計簿",
            lines: ["今月あといくら？", "が、ひと目で"],
            note: "予算の残りをメーターでお知らせ"
        ),
        Page(
            file: "2-entry",
            badge: nil,
            lines: ["よく使う支出は、", "タップ 1 回"],
            note: "テンプレートと電卓ですばやく記録"
        ),
        Page(
            file: "3-review",
            badge: nil,
            lines: ["何に使ったか、", "すぐ分かる"],
            note: "カテゴリごとの内訳と前の月との比べ"
        ),
        Page(
            file: "4-records",
            badge: nil,
            lines: ["毎日の支出を、", "カレンダーで"],
            note: "使わなかった日には印がつきます"
        ),
        Page(
            file: "5-theme",
            badge: nil,
            lines: ["色もアイコンも、", "自分好みに"],
            note: "ライトとダークのテーマを着せ替え"
        )
    ]

    static var screenshots: URL {
        URL(fileURLWithPath: directory)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "store/screenshots/raw")
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
