import CoreText
import Foundation

public enum WidgetFonts {
    private static let fileNames = [
        "KleeOne-Regular.ttf",
        "DotGothic16-Regular.ttf",
        "HachiMaruPop-Regular.ttf"
    ]

    public static func register() {
        let appURL = Bundle.main.bundleURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        for name in fileNames {
            let url = appURL.appending(path: name)
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
