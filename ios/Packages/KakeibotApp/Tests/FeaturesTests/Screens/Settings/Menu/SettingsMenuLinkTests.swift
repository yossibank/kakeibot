@testable import Features
import Foundation
import Testing

struct SettingsMenuLinkTests {
    @Test
    func fillsDeviceAndVersionsIntoContactForm() throws {
        let url = try #require(SettingsMenuLink.contact(
            model: "iPhone 16",
            system: "26.1",
            app: "1.0.0"
        ))
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let items = components.queryItems ?? []

        func value(_ name: String) -> String? {
            items.first { $0.name == name }?.value
        }

        #expect(url.absoluteString.hasPrefix(SettingsMenuLink.contactForm))
        #expect(value("usp") == "pp_url")
        #expect(value("entry.1282978121") == "iPhone 16")
        #expect(value("entry.885969465") == "26.1")
        #expect(value("entry.1211808836") == "1.0.0")
    }

    @Test
    func readsThisDevice() {
        let model = SettingsMenuLink.modelName
        let system = SettingsMenuLink.systemVersion

        #expect(!model.isEmpty)
        #expect(system.split(separator: ".").count >= 2)
    }
}
