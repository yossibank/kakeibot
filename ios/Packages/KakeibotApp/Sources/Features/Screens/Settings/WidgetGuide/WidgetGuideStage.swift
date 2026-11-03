import Core
import DesignSystem
import SwiftUI

struct WidgetGuideStage: View {
    let place: WidgetGuidePlace
    let widget: WidgetGuideWidget
    let size: WidgetGuideSize

    var body: some View {
        FeatureArtCanvas(width: width, height: height) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(12)
        .background(wallpaper, in: .rect(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .stroke(Palette.outline, lineWidth: 1)
        }
    }
}

extension WidgetGuideStage {
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

    static let homeWidth: CGFloat = 364
    static let width: CGFloat = 338
    static let widgetHeight: CGFloat = 170
    static let largeHeight: CGFloat = 382
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
    var width: CGFloat {
        place == .home ? Self.homeWidth : Self.width
    }

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
}
