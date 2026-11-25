import Core
import Foundation
import Store

public extension HomeModel {
    func run() async {
        await loadTemplateOrder()
        await loadHomeLayout()

        await observeAll([
            {
                await self.observe(
                    self.dependencies.database.entryListUpdates(),
                    into: \.input.list,
                    failing: \.input.isListFailed
                )
            },
            {
                await self.observe(
                    self.dependencies.database.templateUpdates(),
                    into: \.input.allTemplates
                )
            },
            {
                await self.observe(
                    self.dependencies.database.budgetUpdates(),
                    into: \.input.budgets
                )
            },
            {
                await self.observe(
                    self.dependencies.database.recurringUpdates(),
                    into: \.input.recurrings
                )
            },
            {
                await self.observe(
                    self.dependencies.database.settingUpdates(.monthStartDay),
                    into: \.input.monthStartDay
                )
            },
            {
                await self.observe(
                    self.dependencies.database.settingUpdates(.budgetCarryoverFrom),
                    into: \.input.carryoverFrom
                )
            },
            {
                await self.observe(
                    self.dependencies.database.settingUpdates(.homeSections),
                    into: \.input.homeSections
                )
            },
            {
                await self.observe(
                    self.dependencies.database.settingUpdates(.homeHiddenSections),
                    into: \.input.homeHiddenSections
                )
            },
            {
                await self.observe(
                    self.dependencies.database.stampBookUpdates(),
                    into: \.input.stampBook
                )
            },
            {
                await self.observeSyncStatus()
            }
        ])
    }

    func load() async {
        do {
            input.list = try await dependencies.database.entryList()
            input.recurrings = try await dependencies.database.recurrings()
        } catch {
            state.errorNotice.show(Self.loadFailedMessage)
        }
    }

    func loadTemplateOrder() async {
        do {
            input.templateOrder = try await dependencies.database.setting(.templateOrder)
        } catch {
            state.errorNotice.show(Self.loadFailedMessage)
        }
    }

    func setTemplateOrder(_ order: TemplateOrder) async {
        input.templateOrder = order

        do {
            try await dependencies.database.setSetting(.templateOrder, to: order)
        } catch {
            state.errorNotice.show(Self.orderSaveFailedMessage, for: error)
        }
    }

    func hide(_ section: HomeSection) async {
        var layout = output.homeLayout

        layout.setHidden(section, true)

        input.homeSections = layout.order
        input.homeHiddenSections = layout.hidden

        do {
            try await dependencies.database.setSetting(.homeSections, to: layout.order)
            try await dependencies.database.setSetting(.homeHiddenSections, to: layout.hidden)
        } catch {
            state.errorNotice.show(Self.layoutSaveFailedMessage, for: error)
        }
    }

    func record(_ item: PeriodRecurring) async {
        do {
            try await dependencies.database.recordRecurring(
                item.recurring.id,
                on: item.date,
                at: dependencies.clock.now
            )
        } catch {
            state.errorNotice.show(Self.saveFailedMessage, for: error)
        }
    }

    @discardableResult
    func record(_ template: EntryTemplate) async -> EntryChange? {
        do {
            let recordable = try await dependencies.database.entryDraft(
                for: template,
                on: state.today
            )

            guard let draft = recordable else {
                return nil
            }

            let saved = try await dependencies.database.saveEntryResult(
                draft,
                at: dependencies.clock.now
            )

            let change = EntryChange(
                kind: .recorded,
                entry: saved.entry,
                label: template.name,
                clearedNoSpendDays: saved.clearedNoSpendDays
            )

            state.outcome.send(change)

            return change
        } catch {
            state.errorNotice.show(Self.saveFailedMessage, for: error)
            return nil
        }
    }
}

private extension HomeModel {
    static let saveFailedMessage = "記録できませんでした"
    static let orderSaveFailedMessage = "並べ順を保存できませんでした"
    static let layoutSaveFailedMessage = "設定を保存できませんでした"

    func loadHomeLayout() async {
        do {
            input.homeSections = try await dependencies.database.setting(.homeSections)
            input.homeHiddenSections = try await dependencies.database.setting(.homeHiddenSections)
        } catch {
            state.errorNotice.show(Self.loadFailedMessage)
        }
    }

    func observeSyncStatus() async {
        do {
            for try await status in dependencies.database.syncStatusUpdates() {
                input.syncStatus = status
            }
        } catch {
            input.syncStatus = .off
        }
    }
}
