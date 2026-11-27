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

        model.state.presented.panel.sheet = nil

        #expect(model.state.markMenuDate == setup.today)

        model.state.present(.stamp(setup.today))

        #expect(model.state.markMenuDate == nil)
        #expect(model.state.sheet == .stamp(setup.today))

        model.state.closeMarkMenu()

        #expect(model.state.sheet == .stamp(setup.today))

        model.state.presented.panel.sheet = nil

        #expect(model.state.presented.panel.current == nil)
    }

    @Test
    func startsEachSheetFromItsFirstLook() async throws {
        let setup = try await Setup()
        let model = RecordsModel(parts: .system(setup.database), today: setup.today)

        model.state.present(.filter)
        model.state.fields.filterTab = .tag
        model.state.presented.panel.sheet = nil
        model.state.present(.filter)

        #expect(model.state.fields.filterTab == .expense)

        model.state.present(.reward(setup.today))
        model.state.presented.adding.show(.mark)
        model.state.presented.panel.sheet = nil
        model.state.present(.stamp(setup.today))

        #expect(model.state.presented.adding.current == nil)

        model.state.presented.adding.show(.mark)
        model.state.finishAddingMark()

        #expect(model.state.presented.adding.current == nil)
    }

    @Test
    func keepsSelectionUntilFinished() async throws {
        let setup = try await Setup()
        let model = RecordsModel(parts: .system(setup.database), today: setup.today)
        let id = Entry.ID()
        let before = model.state.fields.selection

        model.state.select([])
        let started = model.state.fields.selection

        model.state.select([id])
        let selected = model.state.fields.selection

        model.state.finishSelecting()

        #expect(before == nil)
        #expect(started == [])
        #expect(selected == [id])
        #expect(model.state.fields.selection == nil)
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

        #expect(model.state.presented.openItemIds == [second])
    }

    @Test
    func remembersDirectionOfLastMove() async throws {
        let setup = try await Setup()
        let model = RecordsModel(parts: .system(setup.database), today: setup.today)
        let before = model.state.isMovingForward

        model.state.head(forward: false)

        #expect(before)
        #expect(model.state.isMovingForward == false)
    }
}
