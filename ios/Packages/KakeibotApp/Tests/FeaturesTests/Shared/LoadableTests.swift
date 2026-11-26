@testable import FeatureModels
import Testing

struct LoadableTests {
    @Test
    func holdsValueOnlyWhenLoaded() {
        let loading = Loadable<Int>.loading
        let loaded = Loadable<Int>.loaded(1)
        let failed = Loadable<Int>.failed

        #expect(loading.value == nil)
        #expect(loaded.value == 1)
        #expect(failed.value == nil)
        #expect(loaded.isLoaded)
        #expect(failed.isFailed)
    }

    @Test
    func settlesWhenLoadedOrFailed() {
        #expect(!Loadable<Int>.loading.isSettled)
        #expect(Loadable<Int>.loaded(1).isSettled)
        #expect(Loadable<Int>.failed.isSettled)
    }

    @Test
    func retriesOnlyFromFailure() {
        #expect(Loadable<Int>.failed.retrying == .loading)
        #expect(Loadable<Int>.loading.retrying == .loading)
        #expect(Loadable<Int>.loaded(1).retrying == .loaded(1))
    }
}
