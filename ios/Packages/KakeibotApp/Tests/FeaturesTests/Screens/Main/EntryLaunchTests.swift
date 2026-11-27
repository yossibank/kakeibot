import FeatureModels
import Testing

struct EntryLaunchTests {
    @Test
    func startsAndClearsReceipt() {
        var entry = MainModel.EntryLaunch()

        entry.startReceipt()
        let started = entry.startsReceipt
        entry.clearReceipt()

        #expect(started)
        #expect(!entry.startsReceipt)
    }

    @Test
    func finishesWarming() {
        var entry = MainModel.EntryLaunch()
        let before = entry.isWarming

        entry.finishWarming()

        #expect(before)
        #expect(!entry.isWarming)
    }
}
