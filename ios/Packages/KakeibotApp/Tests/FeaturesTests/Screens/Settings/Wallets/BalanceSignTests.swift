import Core
import FeatureModels
import Testing

struct BalanceSignTests {
    @Test
    func followsKindOnlyWhileSignMatchesOldKind() {
        var following = WalletEditModel.BalanceSign(isNegative: false)
        var chosen = WalletEditModel.BalanceSign(isNegative: false)

        following.follow(from: .bank, to: .card)
        chosen.set(true)
        chosen.follow(from: .bank, to: .cash)

        #expect(following.isNegative)
        #expect(chosen.isNegative)
    }
}
