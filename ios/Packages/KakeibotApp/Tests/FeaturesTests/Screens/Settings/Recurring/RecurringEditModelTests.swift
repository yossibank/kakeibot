import Core
import Features
import Foundation
import Store
import Testing

@MainActor
struct RecurringEditModelTests {
    @Test
    func warnsThatRemindersCannotArriveWhenDenied() async throws {
        let setup = try await HomeModelTests.Setup()
        let client = ReminderModelTests.FakePermission(authorization: .denied)
        let model = RecurringEditModel(database: setup.database, today: setup.today)
        await model.load()

        await model.refreshAuthorization(client.permission)
        let withoutReminder = model.isNotificationDenied
        model.remindDaysBefore = 1

        #expect(withoutReminder == false)
        #expect(model.isNotificationDenied)
    }

    @Test
    func doesNotWarnWhenRemindersAreAllowed() async throws {
        let setup = try await HomeModelTests.Setup()
        let client = ReminderModelTests.FakePermission(authorization: .allowed)
        let model = RecurringEditModel(database: setup.database, today: setup.today)
        await model.load()
        model.remindDaysBefore = 1

        await model.refreshAuthorization(client.permission)

        #expect(model.isNotificationDenied == false)
    }

    @Test
    func startsNewRecurringWithGivenTransferType() async throws {
        let setup = try await HomeModelTests.Setup()

        let model = RecurringEditModel(
            database: setup.database,
            today: setup.today,
            type: .transfer
        )

        await model.load()

        #expect(model.type == .transfer)
        #expect(model.categoryId == nil)
        #expect(model.toWalletId != nil)
        #expect(model.toWalletId != model.walletId)
        #expect(model.isChanged == false)
    }

    @Test
    func savesRecurringAndGeneratesEntries() async throws {
        let setup = try await RecordsModelTests.Setup()
        let start = try #require(LocalDate("2026-09-01"))
        let model = RecurringEditModel(database: setup.database, today: setup.today)

        await model.load()
        model.press(.digit(7))
        model.press(.digit(8))
        model.press(.doubleZero)
        model.press(.digit(0))
        model.memo = "家賃"
        model.day = 27
        model.startDate = start
        let saved = await model.save()
        let snapshot = try setup.database.snapshot()

        #expect(saved)
        #expect(snapshot.recurrings.count == 1)
        #expect(snapshot.entries.map(\.date.description) == ["2026-09-27"])
        #expect(snapshot.entries.first?.amount == 78000)
    }

    @Test
    func asksPermissionOnlyWhenSavingWithReminder() async throws {
        let setup = try await RecordsModelTests.Setup()
        let client = ReminderModelTests.FakePermission(authorization: .notDetermined)

        let without = RecurringEditModel(database: setup.database, today: setup.today)
        await without.load()
        without.press(.digit(5))
        without.memo = "家賃"

        _ = await without.save(permission: client.permission)
        let askedWithout = await client.requested

        let model = RecurringEditModel(database: setup.database, today: setup.today)
        await model.load()
        model.press(.digit(5))
        model.memo = "保険"
        model.remindDaysBefore = 1

        let saved = await model.save(permission: client.permission)
        let asked = await client.requested
        let rescheduled = await client.rescheduled

        #expect(rescheduled)
        #expect(saved)
        #expect(!askedWithout)
        #expect(asked)
    }

    @Test
    func suggestsHolidayShiftFromCategory() async throws {
        let setup = try await RecordsModelTests.Setup()
        let model = RecurringEditModel(database: setup.database, today: setup.today)

        await model.load()
        model.select(.income)
        let salary = model.holidayShift

        model.select(.transfer)
        let transfer = model.holidayShift

        model.choose(.none)
        model.select(.income)
        let chosen = model.holidayShift

        #expect(salary == .previous)
        #expect(transfer == .next)
        #expect(chosen == .none)
    }

    @Test
    func presetsCardBillFromCard() async throws {
        let setup = try await RecordsModelTests.Setup()

        let wallet = WalletDraft(
            kind: .card,
            name: "カード",
            mark: .glyph(.card),
            color: "#4A6FA5",
            initialBalance: 0
        )

        let card = try await setup.database.saveWallet(wallet, at: Date())

        let model = RecurringEditModel(
            database: setup.database,
            today: setup.today,
            paying: card.id
        )

        await model.load()

        #expect(model.type == .transfer)
        #expect(model.toWalletId == card.id)
        #expect(model.selectedWallet?.kind == .bank)
        #expect(model.isCardBill)
        #expect(model.closingDay == 31)
        #expect(model.day == 27)
        #expect(model.memo == "カード")
        #expect(model.canSave)
    }

    @Test
    func presetsLoanRepaymentFromLoan() async throws {
        let setup = try await RecordsModelTests.Setup()

        let wallet = WalletDraft(
            kind: .loan,
            name: "奨学金",
            mark: .glyph(.contract),
            color: "#4A6FA5",
            initialBalance: -1_200_000
        )

        let loan = try await setup.database.saveWallet(wallet, at: Date())

        let model = RecurringEditModel(
            database: setup.database,
            today: setup.today,
            paying: loan.id
        )

        await model.load()

        #expect(model.type == .transfer)
        #expect(model.toWalletId == loan.id)
        #expect(!model.isCardBill)
        #expect(model.closingDay == nil)
        #expect(model.memo == "奨学金の返済")
        #expect(!model.canSave)
    }

    @Test
    func savesTransferBetweenWallets() async throws {
        let setup = try await RecordsModelTests.Setup()
        let start = try #require(LocalDate("2026-09-01"))
        let model = RecurringEditModel(database: setup.database, today: setup.today)

        await model.load()
        model.select(.transfer)
        model.press(.digit(3))
        model.press(.digit(0))
        model.press(.doubleZero)
        model.press(.digit(0))
        model.day = 26
        model.startDate = start
        let saved = await model.save()
        let entry = try #require(setup.database.snapshot().entries.first)

        #expect(saved)
        #expect(model.walletTitle == "振替元")
        #expect(entry.type == .transfer)
        #expect(entry.categoryId == nil)
        #expect(entry.toWalletId != nil)
        #expect(entry.toWalletId != entry.walletId)
    }

    @Test
    func refusesSameWalletTransfer() async throws {
        let setup = try await RecordsModelTests.Setup()
        let model = RecurringEditModel(database: setup.database, today: setup.today)

        await model.load()
        model.select(.transfer)
        model.press(.digit(5))
        model.toWalletId = model.walletId
        let saved = await model.save()

        #expect(!saved)
        #expect(model.errorNotice.message == "振替元と振替先を別にしてください")
    }

    @Test
    func refusesEmptyAmount() async throws {
        let setup = try await RecordsModelTests.Setup()
        let model = RecurringEditModel(database: setup.database, today: setup.today)

        await model.load()
        let saved = await model.save()

        #expect(!saved)
        #expect(model.errorNotice.message == "金額を入れてください")
    }
}
