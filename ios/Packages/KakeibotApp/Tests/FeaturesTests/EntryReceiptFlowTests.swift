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
    func opensCameraAfterFirstReceipt() async throws {
        let setup = try await EntryModelTests.Setup()
        try await setup.database.setSetting(.receiptSavedCount, to: 1)
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
        #expect(flow.step == .camera)
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
        let readAmount = await flow.scan([], into: model)

        #expect(readAmount)
        #expect(flow.step == nil)
        #expect(model.amount == 911)
        #expect(model.store == "スーパー青葉")
    }

    @Test
    func reportsUnreadReceipt() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()
        let flow = EntryReceiptFlow { _ in
            ReceiptReading()
        }

        let readAmount = await flow.scan([], into: model)

        #expect(!readAmount)
        #expect(flow.step == nil)
        #expect(model.errorNotice.message == EntryReceiptFlow.unreadMessage)
        #expect(model.amount == 0)
    }
}
