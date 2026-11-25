import Core
import FeatureModels
import Features
import Foundation
import Store
import Testing

extension RecordsModelTests {
    @Test
    func presentsOneThingAtATime() async throws {
        let setup = try await Setup()
        let model = RecordsModel(parts: .system(setup.database), today: setup.today)

        model.state.present(.markMenu(setup.today))

        #expect(model.state.markMenuDate == setup.today)
        #expect(model.state.sheet == nil)

        model.state.sheet = nil

        #expect(model.state.markMenuDate == setup.today)

        model.state.present(.stamp(setup.today))

        #expect(model.state.markMenuDate == nil)
        #expect(model.state.sheet == .stamp(setup.today))

        model.state.closeMarkMenu()

        #expect(model.state.sheet == .stamp(setup.today))

        model.state.sheet = nil

        #expect(model.state.screen.presented == nil)
    }

    @Test
    func startsEachSheetFromItsFirstLook() async throws {
        let setup = try await Setup()
        let model = RecordsModel(parts: .system(setup.database), today: setup.today)

        model.state.present(.filter)
        model.state.screen.filterTab = .tag
        model.state.sheet = nil
        model.state.present(.filter)

        #expect(model.state.screen.filterTab == .expense)

        model.state.present(.reward(setup.today))
        model.state.screen.isAddingMark = true
        model.state.sheet = nil
        model.state.present(.stamp(setup.today))

        #expect(model.state.screen.isAddingMark == false)

        model.state.screen.isAddingMark = true
        model.state.finishAddingMark()

        #expect(model.state.screen.isAddingMark == false)
    }

    @Test
    func keepsSelectionUntilFinished() async throws {
        let setup = try await Setup()
        let model = RecordsModel(parts: .system(setup.database), today: setup.today)
        let id = Entry.ID()
        let before = model.state.screen.selection

        model.state.select([])
        let started = model.state.screen.selection

        model.state.select([id])
        let selected = model.state.screen.selection

        model.state.finishSelecting()

        #expect(before == nil)
        #expect(started == [])
        #expect(selected == [id])
        #expect(model.state.screen.selection == nil)
    }

    @Test
    func opensAndClosesItemsOfEachEntry() async throws {
        let setup = try await Setup()
        let model = RecordsModel(parts: .system(setup.database), today: setup.today)
        let first = Entry.ID()
        let second = Entry.ID()

        model.state.toggleItems(of: first)
        model.state.toggleItems(of: second)
        model.state.toggleItems(of: first)

        #expect(model.state.screen.openItemIds == [second])
    }

    @Test
    func remembersDirectionOfLastMove() async throws {
        let setup = try await Setup()
        let model = RecordsModel(parts: .system(setup.database), today: setup.today)
        let before = model.state.screen.isMovingForward

        model.state.head(forward: false)

        #expect(before)
        #expect(model.state.screen.isMovingForward == false)
    }
}
