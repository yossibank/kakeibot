import Core
import Testing

struct AppVersionTests {
    @Test(arguments: try versionCases)
    func findsNewerVersion(fixture: VersionCase) {
        let isNewer = AppVersion.isNewer(fixture.latest, than: fixture.seen)

        #expect(isNewer == fixture.isNewer)
    }
}

extension AppVersionTests {
    struct VersionCase: Decodable, Sendable, CustomTestStringConvertible {
        let summary: String
        let latest: String
        let seen: String?
        let isNewer: Bool

        var testDescription: String {
            summary
        }
    }
}

private extension AppVersionTests {
    static var versionCases: [VersionCase] {
        get throws {
            try CoreFixture.cases("app/app-version.json")
        }
    }
}
