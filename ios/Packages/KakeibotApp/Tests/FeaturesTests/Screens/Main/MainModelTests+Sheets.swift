import Core
@testable import FeatureModels
import Store
import Testing

extension MainModelTests {
    @Test
    func closesOpenSheetBeforeOpeningRoute() async throws {
        let setup = try await TemplateSetup()
        let model = Self.model(setup)
        model.state.select(.records)
        model.state.presented.sheet.show(.settings)
        var whileWaiting: Seen?

        let route = model.perform {
            await $0.open(.entry(setup.date))
        }
        let probe = model.perform {
            whileWaiting = Self.seen(in: $0)
        }

        await route.value
        await probe.value

        #expect(whileWaiting == Seen(sheet: nil, tab: .records))
        #expect(Self.seen(in: model) == Seen(sheet: .new, tab: .home))
    }

    @Test
    func opensSecondRouteWhileFirstWaits() async throws {
        let setup = try await TemplateSetup()
        let model = Self.model(setup)
        let id = Recurring.ID()
        model.state.select(.records)
        model.state.presented.sheet.show(.settings)
        var afterSecond: Seen?

        let first = model.perform {
            await $0.open(.entry(setup.date))
        }
        let second = model.perform {
            await $0.open(.recurring(id))
            afterSecond = Self.seen(in: $0)
        }

        await first.value
        await second.value

        #expect(afterSecond == Seen(sheet: .recurring(id), tab: .records))
        #expect(Self.seen(in: model) == Seen(sheet: .new, tab: .home))
    }

    @Test
    func closesSheetBeforeMovingToTab() async throws {
        let setup = try await TemplateSetup()
        let model = Self.model(setup)
        model.state.presented.sheet.show(.whatsNew(seenVersion: nil))
        var whileWaiting: Seen?

        let move = model.perform {
            await $0.move(to: .review, opening: nil)
        }
        let probe = model.perform {
            whileWaiting = Self.seen(in: $0)
        }

        await move.value
        await probe.value

        #expect(whileWaiting == Seen(sheet: nil, tab: .home))
        #expect(Self.seen(in: model) == Seen(sheet: nil, tab: .review))
    }

    @Test
    func waitsBeforeMovingEvenWithoutSheet() async throws {
        let setup = try await TemplateSetup()
        let model = Self.model(setup)
        var whileWaiting: Seen?

        let move = model.perform {
            await $0.move(to: .home, opening: .new)
        }
        let probe = model.perform {
            whileWaiting = Self.seen(in: $0)
        }

        await move.value
        await probe.value
        await model.move(to: nil, opening: .setup(.budget))

        #expect(whileWaiting == Seen(sheet: nil, tab: .home))
        #expect(Self.seen(in: model) == Seen(sheet: .setup(.budget), tab: .home))
    }

    @Test
    func addsEntryOnChosenDate() async throws {
        let setup = try await TemplateSetup()
        let model = Self.model(setup)
        let date = setup.date.adding(days: -5)

        model.addEntry(on: date)

        #expect(model.state.presented.sheet.current == .new)
        #expect(model.state.submodels.draft.state.payment.date == date)
        #expect(model.state.submodels.draft.state.type == .expense)
    }

    @Test
    func addsTransferWithDraft() async throws {
        let setup = try await TemplateSetup()
        let model = Self.model(setup)

        model.addTransfer()

        #expect(model.state.presented.sheet.current == .transfer)
        #expect(model.state.submodels.draft.state.type == .transfer)
    }

    @Test
    func replacesDraftAfterSheetCloses() async throws {
        let setup = try await TemplateSetup()
        let model = Self.model(setup)
        let first = model.state.submodels.draft
        model.addTransfer()
        model.state.presented.sheet.closeAll()

        await model.prepareDraft().value

        #expect(model.state.submodels.draft !== first)
        #expect(model.state.submodels.draft.state.type == .expense)
        #expect(model.state.submodels.draft.state.payment.date == setup.date)
        #expect(model.state.submodels.draft.output.isLoaded)
        #expect(!first.output.isLoaded)
    }

    @Test
    func replacesDraftWhenDayChanges() async throws {
        let setup = try await TemplateSetup()
        let model = Self.model(setup)
        let first = model.state.submodels.draft
        let next = setup.date.adding(days: 1)

        await model.setToday(next).value

        #expect(first.state.today == next)
        #expect(model.input.today == next)
        #expect(model.state.submodels.draft !== first)
        #expect(model.state.submodels.draft.state.payment.date == next)
    }
}
