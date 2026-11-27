import Core
@testable import FeatureModels
@testable import Features
import Foundation
import Store
import Testing

@MainActor
struct EntryReceiptFlowTests {
    @Test
    func showsGuideBeforeFirstReceipt() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()
        let flow = EntryReceiptFlow { _ in
            ReceiptReading()
        }

        flow.start(for: model, isPro: false)
        let guide = flow.state.step
        flow.confirmGuide()

        #expect(guide == .guide)
        #expect(flow.state.step == .camera)
        #expect(flow.output.isScanning)
    }

    @Test
    func preparesModelWhenCameraOpens() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()
        var prepared = 0
        let flow = EntryReceiptFlow { _ in
            ReceiptReading()
        } prepare: {
            prepared += 1
        }

        flow.start(for: model, isPro: false)
        let beforeCamera = prepared
        flow.confirmGuide()

        #expect(beforeCamera == 1)
        #expect(prepared == 2)
    }

    @Test
    func showsGuideAfterFirstReceipt() async throws {
        let setup = try await EntryModelTests.Setup()
        try await setup.database.setSetting(.receiptSavedCount, to: 1)
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()
        let flow = EntryReceiptFlow { _ in
            ReceiptReading()
        }

        flow.start(for: model, isPro: true)

        #expect(flow.state.step == .guide)
        #expect(flow.state.presented.offer.current == nil)
    }

    @Test
    func opensCameraWhenGuideIsHidden() async throws {
        let setup = try await EntryModelTests.Setup()
        try await setup.database.setSetting(.receiptGuideHidden, to: true)
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()
        let flow = EntryReceiptFlow { _ in
            ReceiptReading()
        }

        flow.start(for: model, isPro: false)

        #expect(flow.state.step == .camera)
        #expect(flow.state.presented.offer.current == nil)
    }

    @Test
    func hidesGuideWhenChecked() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()
        let flow = EntryReceiptFlow { _ in
            ReceiptReading()
        }

        flow.start(for: model, isPro: false)
        flow.state.fields.hidesGuide = true
        flow.cancel()
        await flow.saveGuideChoice(for: model)
        let saved = try await setup.database.setting(.receiptGuideHidden)

        flow.start(for: model, isPro: false)

        #expect(saved)
        #expect(!flow.state.fields.hidesGuide)
        #expect(flow.state.step == .camera)
    }

    @Test
    func keepsGuideWhenUnchecked() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()
        let flow = EntryReceiptFlow { _ in
            ReceiptReading()
        }

        flow.start(for: model, isPro: false)
        flow.confirmGuide()
        await flow.saveGuideChoice(for: model)
        let saved = try await setup.database.setting(.receiptGuideHidden)

        flow.cancel()
        flow.start(for: model, isPro: false)

        #expect(!saved)
        #expect(flow.state.step == .guide)
    }

    @Test
    func offersProAfterFreeReceipts() async throws {
        let setup = try await EntryModelTests.Setup()
        try await setup.database.setSetting(.receiptSavedCount, to: EntryModel.freeReceiptLimit)
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()
        let flow = EntryReceiptFlow { _ in
            ReceiptReading()
        }

        flow.start(for: model, isPro: false)
        let offer = flow.state.presented.offer.current
        let step = flow.state.step
        flow.closeOffer()
        flow.start(for: model, isPro: true)

        #expect(offer == EntryReceiptFlow.offerFeature)
        #expect(step == nil)
        #expect(flow.state.presented.offer.current == nil)
        #expect(flow.state.step == .guide)
    }

    @Test
    func appliesScannedReceipt() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()
        let flow = EntryReceiptFlow { _ in
            ReceiptReading(store: "スーパー青葉", total: 911)
        }

        flow.confirmGuide()
        let outcome = await flow.scan([], into: model)

        #expect(outcome == .read(itemCount: 0, hasAmount: true))
        #expect(flow.state.step == nil)
        #expect(model.output.amount == 911)
        #expect(model.state.fields.store == "スーパー青葉")
        #expect(model.state.errorNotice.message == EntryReceiptFlow.totalMessage)
    }

    @Test
    func countsScannedItems() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()
        let flow = EntryReceiptFlow { _ in
            ReceiptReading(
                items: [
                    EntryItem.Draft(name: "牛乳", amount: 396),
                    EntryItem.Draft(name: "食パン", amount: 220)
                ]
            )
        }

        let outcome = await flow.scan([], into: model)

        #expect(outcome == .read(itemCount: 2, hasAmount: true))
        #expect(model.state.errorNotice.message == nil)
        #expect(model.output.amount == 616)
    }

    @Test
    func placesReadOutcomeInState() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()
        let flow = EntryReceiptFlow { _ in
            ReceiptReading(items: [EntryItem.Draft(name: "牛乳", amount: 396)])
        }

        let outcome = await flow.scan([], into: model)
        let first = flow.state.outcome
        await flow.scan([], into: model)

        #expect(first.value == outcome)
        #expect(first.value == .read(itemCount: 1, hasAmount: true))
        #expect(flow.state.outcome != first)
    }

    @Test
    func keepsKeypadWhenAmountIsUnread() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()
        model.state.press(.digit(5))
        let flow = EntryReceiptFlow { _ in
            ReceiptReading(store: "スーパー青葉")
        }

        let outcome = await flow.scan([], into: model)

        #expect(outcome == .read(itemCount: 0, hasAmount: false))
        #expect(model.state.errorNotice.message == nil)
        #expect(model.output.amount == 5)
    }

    @Test
    func reportsUnreadReceipt() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()
        let flow = EntryReceiptFlow { _ in
            ReceiptReading()
        }

        let outcome = await flow.scan([], into: model)

        #expect(outcome == .unread)
        #expect(flow.state.outcome.value == nil)
        #expect(flow.state.step == nil)
        #expect(model.state.errorNotice.message == EntryReceiptFlow.unreadMessage)
        #expect(model.output.amount == 0)
    }
}
