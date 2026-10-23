import CoreText
import Foundation

public enum WidgetFonts {
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

private extension WidgetFonts {
    static let fileNames = [
        "KleeOne-Regular.ttf",
        "DotGothic16-Regular.ttf"
    ]
}
