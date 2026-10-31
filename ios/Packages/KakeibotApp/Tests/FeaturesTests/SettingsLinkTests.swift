@testable import Features
import Foundation
import Testing

struct SettingsLinkTests {
    @Test
    func fillsDeviceAndVersionsIntoContactForm() throws {
        let url = try #require(SettingsLink.contact(
            model: "iPhone17,3",
            system: "26.1",
            app: "1.0.0"
        ))
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let items = components.queryItems ?? []

        func value(_ name: String) -> String? {
            items.first { $0.name == name }?.value
        }

        #expect(url.absoluteString.hasPrefix(SettingsLink.contactForm))
        #expect(value("usp") == "pp_url")
        #expect(value("entry.1282978121") == "iPhone17,3")
        #expect(value("entry.885969465") == "26.1")
        #expect(value("entry.1211808836") == "1.0.0")
    }

    @Test
    func readsThisDevice() {
        let model = SettingsLink.modelIdentifier
        let system = SettingsLink.systemVersion

        #expect(!model.isEmpty)
        #expect(system.split(separator: ".").count >= 2)
    }
}
