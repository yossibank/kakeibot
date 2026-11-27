import FeatureModels
import Testing

struct PeriodCursorTests {
    @Test
    func movesBackAndStopsAtCurrent() {
        var cursor = ReviewModel.PeriodCursor()

        cursor.move(by: -2)
        let back = cursor
        cursor.move(by: 3)

        #expect(back.offset == -2)
        #expect(!back.isMovingForward)
        #expect(cursor.offset == -2)
        #expect(!cursor.canMove(by: 3))
    }

    @Test
    func returnsToCurrentMovingForward() {
        var cursor = ReviewModel.PeriodCursor()
        cursor.move(by: -1)

        cursor.moveToCurrent()

        #expect(cursor.isCurrent)
        #expect(cursor.isMovingForward)
    }

    @Test
    func restartsWithGivenDirection() {
        var cursor = ReviewModel.PeriodCursor()
        cursor.move(by: -3)

        cursor.restart(movingForward: false)

        #expect(cursor.offset == 0)
        #expect(!cursor.isMovingForward)
    }
}
