@testable import AppFeature
import Store
import Testing

extension AppModelTests {
    @Test
    func detectsForegroundAfterInactive() {
        let model = AppModel(openDatabase: AppDatabase.inMemory)

        let results = [
            model.state.receiveScene(.inactive),
            model.state.receiveScene(.active),
            model.state.receiveScene(.background),
            model.state.receiveScene(.inactive),
            model.state.receiveScene(.active),
            model.state.receiveScene(.active)
        ]

        #expect(results == [false, false, false, false, true, false])
    }

    @Test
    func revealsContentWhenCurtainLeaves() {
        let model = AppModel(openDatabase: AppDatabase.inMemory)
        let covering = model.state.curtain

        model.state.leaveCurtain()
        let leaving = model.state.curtain
        model.state.finishCurtain()
        model.state.leaveCurtain()

        #expect(covering.isShown && !covering.isRevealed)
        #expect(leaving.isShown && leaving.isRevealed)
        #expect(model.state.curtain == .finished)
        #expect(!model.state.curtain.isShown && model.state.curtain.isRevealed)
    }

    @Test
    func remembersSweepAndHomeLoad() {
        let model = AppModel(openDatabase: AppDatabase.inMemory)
        let before = [model.state.hasSwept, model.state.isHomeLoaded]

        model.state.finishSweep()
        model.state.markHomeLoaded()

        #expect(before == [false, false])
        #expect(model.state.hasSwept)
        #expect(model.state.isHomeLoaded)
    }
}
