import Foundation

enum SettingsLink {
    static let appStoreId = "6829072935"
    static let contact = URL(string: "https://forms.gle/hgjZHj6FcCp61tiV6")
    static let review =
        URL(string: "https://apps.apple.com/app/id\(appStoreId)?action=write-review")
}
