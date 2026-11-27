import Core
import FeatureModels
import Testing

struct PendingDayTests {
    @Test
    func takesPickedDayOnce() throws {
        let date = try #require(LocalDate("2026-10-05"))
        var pending = HomeModel.PendingDay()

        let empty = pending.take()
        pending.pick(date)
        let first = pending.take()
        let second = pending.take()

        #expect(empty == nil)
        #expect(first == date)
        #expect(second == nil)
    }
}
