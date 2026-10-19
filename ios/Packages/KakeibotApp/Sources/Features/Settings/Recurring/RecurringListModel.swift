import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class RecurringListModel: ScreenModel {
    public private(set) var recurrings: [Recurring] = []
    public private(set) var movingOrder: [Recurring.ID]?
    public private(set) var list: EntryList?

    public internal(set) var errorNotice = ErrorNotice()

    let today: LocalDate

    private let database: AppDatabase

    public init(
        database: AppDatabase,
        today: LocalDate
    ) {
        self.database = database
        self.today = today
    }
}

public extension RecurringListModel {
    struct Row: Identifiable {
        public let id: Recurring.ID
        public let title: String
        public let detail: String
        public let amount: Int
        public let type: Entry.Kind
        public let icon: Icon?
        public let next: LocalDate?
    }

    struct MonthTotal: Equatable {
        public let expense: Int
        public let income: Int
    }

    var rows: [Row] {
        guard let list else {
            return []
        }

        return shown.map { row(for: $0, in: list) }
    }

    var hiddenRows: [Row] {
        guard let list else {
            return []
        }

        return hidden.map { row(for: $0, in: list) }
    }

    var monthTotal: MonthTotal {
        let month = today.yearMonth.period(startingOn: .first)

        return MonthTotal(
            expense: visible.total(of: .expense, in: month),
            income: visible.total(of: .income, in: month)
        )
    }

    func move(
        _ id: Recurring.ID,
        to index: Int
    ) {
        var order = movingOrder ?? visible.map(\.id)

        guard let from = order.firstIndex(of: id) else {
            return
        }

        let to = min(max(index, 0), order.count - 1)

        guard from != to else {
            return
        }

        order.remove(at: from)
        order.insert(id, at: to)
        movingOrder = order
    }

    func delete(_ id: Recurring.ID) async {
        do {
            try await database.deleteRecurring(id)
        } catch {
            errorNotice.show(Self.deleteFailedMessage)
        }
    }

    func hide(_ id: Recurring.ID) async {
        movingOrder = nil
        await setHidden(id, isHidden: true, failure: Self.hideFailedMessage)
    }

    func show(_ id: Recurring.ID) async {
        await setHidden(id, isHidden: false, failure: Self.showFailedMessage)
    }

    func finishMoving() async {
        guard let movingOrder else {
            return
        }

        do {
            let ids = movingOrder + hidden.map(\.id)
            try await database.reorderRecurrings(ids, at: Date())
        } catch {
            errorNotice.show(Self.saveFailedMessage)
        }

        self.movingOrder = nil
    }

    func editModel(for id: Recurring.ID?) -> RecurringEditModel {
        RecurringEditModel(database: database, today: today, editing: id)
    }

    func observe() async {
        await withDiscardingTaskGroup { group in
            group.addTask {
                await self.observeRecurrings()
            }

            group.addTask {
                await self.observeList()
            }
        }
    }
}

private extension RecurringListModel {
    static let loadFailedMessage = "固定費を読めませんでした"
    static let saveFailedMessage = "並びを保存できませんでした"
    static let deleteFailedMessage = "固定費を消せませんでした"
    static let hideFailedMessage = "非表示にできませんでした"
    static let showFailedMessage = "表示に戻せませんでした"

    var visible: [Recurring] {
        recurrings.filter { $0.archivedAt == nil }
    }

    var hidden: [Recurring] {
        recurrings.filter { $0.archivedAt != nil }
    }

    var shown: [Recurring] {
        guard let movingOrder else {
            return visible
        }

        return movingOrder.compactMap { id in
            visible.first { $0.id == id }
        }
    }

    func setHidden(
        _ id: Recurring.ID,
        isHidden: Bool,
        failure: String
    ) async {
        do {
            try await database.setRecurringHidden(
                id,
                isHidden: isHidden,
                today: today,
                at: Date()
            )
        } catch {
            errorNotice.show(failure)
        }
    }

    static func title(of type: Entry.Kind) -> String {
        type == .transfer ? "振替" : "固定費"
    }

    func observeRecurrings() async {
        await observe(
            database.recurringUpdates(includingHidden: true),
            failure: Self.loadFailedMessage
        ) { recurrings in
            self.recurrings = recurrings
        }
    }

    func observeList() async {
        await observe(
            database.entryListUpdates(),
            failure: Self.loadFailedMessage
        ) { list in
            self.list = list
        }
    }

    func row(
        for recurring: Recurring,
        in list: EntryList
    ) -> Row {
        let category = recurring.categoryId.flatMap { list.categories[$0] }
        let wallet = list.wallets[recurring.walletId]
        let memo = recurring.memo.flatMap { $0.isEmpty ? nil : $0 }

        let schedule = RecurringText.schedule(
            recurring.frequency,
            month: recurring.month ?? recurring.startDate.month,
            day: recurring.day
        )

        let destination = recurring.toWalletId.flatMap { list.wallets[$0] }

        let route = [wallet?.name, destination?.name]
            .compactMap(\.self)
            .joined(separator: " → ")

        let place = recurring.type == .transfer ? route : wallet?.name

        let iconId = recurring.type == .transfer
            ? wallet?.iconId
            : category?.iconId

        return Row(
            id: recurring.id,
            title: memo ?? category?.name ?? Self.title(of: recurring.type),
            detail: [schedule, place].rowDetail ?? "",
            amount: recurring.amount,
            type: recurring.type,
            icon: iconId.flatMap { list.icons[$0] },
            next: recurring.nextDate(onOrAfter: today)
        )
    }
}
