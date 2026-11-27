import Core
import FeatureModels
import Testing

struct WalletWorkTests {
    @Test
    func endsOnlyTheWalletItBegan() {
        let first = Wallet.ID()
        let second = Wallet.ID()
        var work = SyncModel.WalletWork()

        work.begin(first)
        work.begin(second)
        work.end(first)
        let kept = work.wallet
        let isWorking = work.isWorking(on: second)
        work.end(second)

        #expect(kept == second)
        #expect(isWorking)
        #expect(!work.isWorking(on: first))
        #expect(work.wallet == nil)
    }
}
