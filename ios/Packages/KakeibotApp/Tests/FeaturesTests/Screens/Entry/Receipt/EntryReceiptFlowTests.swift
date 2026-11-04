import Core
@testable import Features
import Foundation
import Store
import Testing

@MainActor
struct EntryReceiptFlowTests {
    @Test
    func showsGuideBeforeFirstReceipt() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()
        let flow = EntryReceiptFlow { _ in
            ReceiptReading()
        }

        flow.start(for: model, isPro: false)
        let guide = flow.step
        flow.confirmGuide()

        #expect(guide == .guide)
        #expect(flow.step == .camera)
        #expect(flow.isScanning)
    }

    @Test
    func preparesModelWhenCameraOpens() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = EntryModel(database: setup.database, date: setup.date)
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
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()
        let flow = EntryReceiptFlow { _ in
            ReceiptReading()
        }

        flow.start(for: model, isPro: true)

        #expect(flow.step == .guide)
        #expect(flow.offer == nil)
    }

    @Test
    func opensCameraWhenGuideIsHidden() async throws {
        let setup = try await EntryModelTests.Setup()
        try await setup.database.setSetting(.receiptGuideHidden, to: true)
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()
        let flow = EntryReceiptFlow { _ in
            ReceiptReading()
        }

        flow.start(for: model, isPro: false)

        #expect(flow.step == .camera)
        #expect(flow.offer == nil)
    }

    @Test
    func hidesGuideWhenChecked() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()
        let flow = EntryReceiptFlow { _ in
            ReceiptReading()
        }

        flow.start(for: model, isPro: false)
        flow.hidesGuide = true
        flow.cancel()
        await flow.saveGuideChoice(for: model)
        let saved = try await setup.database.setting(.receiptGuideHidden)

        flow.start(for: model, isPro: false)

        #expect(saved)
        #expect(!flow.hidesGuide)
        #expect(flow.step == .camera)
    }

    @Test
    func keepsGuideWhenUnchecked() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = EntryModel(database: setup.database, date: setup.date)
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
        #expect(flow.step == .guide)
    }

    @Test
    func offersProAfterFreeReceipts() async throws {
        let setup = try await EntryModelTests.Setup()
        try await setup.database.setSetting(.receiptSavedCount, to: EntryModel.freeReceiptLimit)
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()
        let flow = EntryReceiptFlow { _ in
            ReceiptReading()
        }

        flow.start(for: model, isPro: false)
        let offer = flow.offer
        let step = flow.step
        flow.closeOffer()
        flow.start(for: model, isPro: true)

        #expect(offer == EntryReceiptFlow.offerFeature)
        #expect(step == nil)
        #expect(flow.offer == nil)
        #expect(flow.step == .guide)
    }

    @Test
    func appliesScannedReceipt() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()
        let flow = EntryReceiptFlow { _ in
            ReceiptReading(store: "スーパー青葉", total: 911)
        }

        flow.confirmGuide()
        let outcome = await flow.scan([], into: model)

        #expect(outcome == .read(itemCount: 0, hasAmount: true))
        #expect(flow.step == nil)
        #expect(model.amount == 911)
        #expect(model.store == "スーパー青葉")
        #expect(model.errorNotice.message == EntryReceiptFlow.totalMessage)
    }

    @Test
    func countsScannedItems() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = EntryModel(database: setup.database, date: setup.date)
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
        #expect(model.errorNotice.message == nil)
        #expect(model.amount == 616)
    }

    @Test
    func keepsKeypadWhenAmountIsUnread() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()
        model.press(.digit(5))
        let flow = EntryReceiptFlow { _ in
            ReceiptReading(store: "スーパー青葉")
        }

        let outcome = await flow.scan([], into: model)

        #expect(outcome == .read(itemCount: 0, hasAmount: false))
        #expect(model.errorNotice.message == nil)
        #expect(model.amount == 5)
    }

    @Test
    func reportsUnreadReceipt() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()
        let flow = EntryReceiptFlow { _ in
            ReceiptReading()
        }

        let outcome = await flow.scan([], into: model)

        #expect(outcome == .unread)
        #expect(flow.step == nil)
        #expect(model.errorNotice.message == EntryReceiptFlow.unreadMessage)
        #expect(model.amount == 0)
    }
}
