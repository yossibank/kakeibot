@testable import Features
import Testing

@MainActor
struct WhatsNewModelTests {
    @Test
    func showsChosenVersion() throws {
        let oldest = try #require(WhatsNewRelease.all.last)
        let model = WhatsNewModel(seenVersion: nil, version: WhatsNewRelease.latestVersion)

        model.state.choose(oldest.version)

        #expect(model.state.version == oldest.version)
        #expect(model.output.release?.version == oldest.version)
    }

    @Test
    func showsLatestReleaseForUnknownVersion() {
        let model = WhatsNewModel(seenVersion: nil, version: "0.0.0")

        #expect(model.output.release?.version == WhatsNewRelease.all.first?.version)
    }

    @Test
    func marksReleasesNewerThanSeenVersion() throws {
        let latest = try #require(WhatsNewRelease.all.first)
        let oldest = try #require(WhatsNewRelease.all.last)
        let model = WhatsNewModel(seenVersion: oldest.version, version: latest.version)

        #expect(model.output.isNew(latest))
        #expect(!model.output.isNew(oldest))
    }
}
