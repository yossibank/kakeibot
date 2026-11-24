import Core
@testable import FeatureModels
@testable import Features
import Foundation
import Store
import Testing

@MainActor
struct RecurringEditModelTests {
    @Test
    func warnsThatRemindersCannotArriveWhenDenied() async throws {
        let setup = try await HomeModelTests.Setup()
        let client = ReminderModelTests.FakePermission(authorization: .denied)
        let model = RecurringEditModel(database: setup.database, clock: .system, today: setup.today)
        await model.load()

        await model.refreshAuthorization(client.permission)
        let withoutReminder = model.output.isNotificationDenied
        model.state.schedule.remindDaysBefore = 1

        #expect(withoutReminder == false)
        #expect(model.output.isNotificationDenied)
    }

    @Test
    func doesNotWarnWhenRemindersAreAllowed() async throws {
        let setup = try await HomeModelTests.Setup()
        let client = ReminderModelTests.FakePermission(authorization: .allowed)
        let model = RecurringEditModel(database: setup.database, clock: .system, today: setup.today)
        await model.load()
        model.state.schedule.remindDaysBefore = 1

        await model.refreshAuthorization(client.permission)

        #expect(model.output.isNotificationDenied == false)
    }

    @Test
    func startsNewRecurringWithGivenTransferType() async throws {
        let setup = try await HomeModelTests.Setup()

        let model = RecurringEditModel(
            database: setup.database,
            clock: .system,
            today: setup.today,
            type: .transfer
        )

        await model.load()

        #expect(model.state.type == .transfer)
        #expect(model.state.categoryId == nil)
        #expect(model.state.toWalletId != nil)
        #expect(model.state.toWalletId != model.state.walletId)
        #expect(model.isChanged == false)
    }

    @Test
    func opensScheduleWhenAddingRecurring() async throws {
        let setup = try await HomeModelTests.Setup()

        let model = RecurringEditModel(database: setup.database, clock: .system, today: setup.today)

        #expect(model.state.isScheduleOpen)
    }

    @Test
    func closesScheduleWhenEditingRecurring() async throws {
        let setup = try await HomeModelTests.Setup()

        let model = RecurringEditModel(
            database: setup.database,
            clock: .system,
            today: setup.today,
            editing: Recurring.ID()
        )

        #expect(!model.state.isScheduleOpen)
    }

    @Test
    func doesNotCountClosingScheduleAsChange() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = RecurringEditModel(database: setup.database, clock: .system, today: setup.today)
        await model.load()

        model.state.isScheduleOpen = false

        #expect(model.isChanged == false)
    }

    @Test
    func savesRecurringAndGeneratesEntries() async throws {
        let setup = try await RecordsModelTests.Setup()
        let start = try #require(LocalDate("2026-09-01"))
        let model = RecurringEditModel(database: setup.database, clock: .system, today: setup.today)

        await model.load()
        model.state.press(.digit(7))
        model.state.press(.digit(8))
        model.state.press(.doubleZero)
        model.state.press(.digit(0))
        model.state.memo = "家賃"
        model.state.schedule.day = 27
        model.state.schedule.startDate = start
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

        let without = RecurringEditModel(
            database: setup.database,
            clock: .system,
            today: setup.today
        )
        await without.load()
        without.state.press(.digit(5))
        without.state.memo = "家賃"

        _ = await without.save(permission: client.permission)
        let askedWithout = await client.requested

        let model = RecurringEditModel(database: setup.database, clock: .system, today: setup.today)
        await model.load()
        model.state.press(.digit(5))
        model.state.memo = "保険"
        model.state.schedule.remindDaysBefore = 1

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
        let model = RecurringEditModel(database: setup.database, clock: .system, today: setup.today)

        await model.load()
        model.select(.income)
        let salary = model.state.schedule.holidayShift

        model.select(.transfer)
        let transfer = model.state.schedule.holidayShift

        model.state.schedule.choose(.none)
        model.select(.income)
        let chosen = model.state.schedule.holidayShift

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

        let card = try await setup.database.save(wallet, at: Date())

        let model = RecurringEditModel(
            database: setup.database,
            clock: .system,
            today: setup.today,
            paying: card.id
        )

        await model.load()

        #expect(model.state.type == .transfer)
        #expect(model.state.toWalletId == card.id)
        #expect(model.output.selectedWallet?.kind == .bank)
        #expect(model.output.isCardBill)
        #expect(model.state.schedule.closingDay == 31)
        #expect(model.state.schedule.day == 27)
        #expect(model.state.memo == "カード")
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

        let loan = try await setup.database.save(wallet, at: Date())

        let model = RecurringEditModel(
            database: setup.database,
            clock: .system,
            today: setup.today,
            paying: loan.id
        )

        await model.load()

        #expect(model.state.type == .transfer)
        #expect(model.state.toWalletId == loan.id)
        #expect(!model.output.isCardBill)
        #expect(model.state.schedule.closingDay == nil)
        #expect(model.state.memo == "奨学金の返済")
        #expect(!model.canSave)
    }

    @Test
    func plansRepaymentFromLoanBalance() async throws {
        let model = try await Self.loanModel()
        let end = try #require(LocalDate("2046-09-27"))

        #expect(model.output.isLoanRepayment)
        #expect(model.output.usesAutoCount)
        #expect(model.output.scheduledEndDate == end)
        #expect(model.output.repaymentCount == 240)
        #expect(model.output.plannedTotal == 3_896_752)
        #expect(model.output.balanceGap == nil)
        #expect(model.output.draft.endDate == end)
        #expect(model.output.draft.finalAmount == 16587)
    }

    @Test
    func leavesRemainderForLastPaymentWhenCountIsLonger() async throws {
        let model = try await Self.loanModel()

        model.prepareCount()
        model.pressCount(.delete)
        model.pressCount(.digit(1))

        #expect(!model.output.usesAutoCount)
        #expect(model.output.repaymentCount == 241)
        #expect(model.output.draft.finalAmount == 352)
        #expect(model.output.balanceGap == nil)
    }

    @Test
    func showsGapWhenCountIsShort() async throws {
        let model = try await Self.loanModel()

        model.prepareCount()
        model.pressCount(.delete)
        model.pressCount(.delete)
        model.pressCount(.digit(3))
        model.pressCount(.digit(9))

        #expect(model.output.repaymentCount == 239)
        #expect(model.output.draft.finalAmount == 0)
        #expect(model.output.balanceGap == -16587)

        model.state.repayment.useAutoCount()

        #expect(model.output.repaymentCount == 240)
        #expect(model.output.balanceGap == nil)
    }

    @Test
    func savesTransferBetweenWallets() async throws {
        let setup = try await RecordsModelTests.Setup()
        let start = try #require(LocalDate("2026-09-01"))
        let model = RecurringEditModel(database: setup.database, clock: .system, today: setup.today)

        await model.load()
        model.select(.transfer)
        model.state.press(.digit(3))
        model.state.press(.digit(0))
        model.state.press(.doubleZero)
        model.state.press(.digit(0))
        model.state.schedule.day = 26
        model.state.schedule.startDate = start
        let saved = await model.save()
        let entry = try #require(setup.database.snapshot().entries.first)

        #expect(saved)
        #expect(model.output.walletTitle == "振替元")
        #expect(entry.type == .transfer)
        #expect(entry.categoryId == nil)
        #expect(entry.toWalletId != nil)
        #expect(entry.toWalletId != entry.walletId)
    }

    @Test
    func refusesSameWalletTransfer() async throws {
        let setup = try await RecordsModelTests.Setup()
        let model = RecurringEditModel(database: setup.database, clock: .system, today: setup.today)

        await model.load()
        model.select(.transfer)
        model.state.press(.digit(5))
        model.state.toWalletId = model.state.walletId
        let saved = await model.save()

        #expect(!saved)
        #expect(model.state.errorNotice.message == "振替元と振替先を別にしてください")
    }

    @Test
    func refusesEmptyAmount() async throws {
        let setup = try await RecordsModelTests.Setup()
        let model = RecurringEditModel(database: setup.database, clock: .system, today: setup.today)

        await model.load()
        let saved = await model.save()

        #expect(!saved)
        #expect(model.state.errorNotice.message == "金額を入れてください")
    }
}

private extension RecurringEditModelTests {
    static func loanModel() async throws -> RecurringEditModel {
        let setup = try await RecordsModelTests.Setup()
        let start = try #require(LocalDate("2026-10-27"))

        let wallet = WalletDraft(
            kind: .loan,
            name: "奨学金",
            mark: .glyph(.scholarship),
            color: "#4A6FA5",
            initialBalance: -3_896_752
        )

        let loan = try await setup.database.save(wallet, at: Date())

        let model = RecurringEditModel(
            database: setup.database,
            clock: .system,
            today: setup.today,
            paying: loan.id
        )

        await model.load()
        model.state.schedule.startDate = start
        model.state.schedule.choose(.none)

        for key in [AmountCalculator.Key.digit(1), .digit(6), .digit(2), .digit(3), .digit(5)] {
            model.state.press(key)
        }

        return model
    }
}
