import Core

public extension EntryList {
    func icon(for template: EntryTemplate) -> Icon? {
        let category = categories[template.categoryId]

        return category.flatMap { icons[$0.iconId] }
    }

    func ordered(
        _ templates: [EntryTemplate],
        by order: TemplateOrder,
        today: LocalDate
    ) -> [EntryTemplate] {
        let uses = order == .frequent ? templateUses(through: today) : [:]

        return templates.sorted { lhs, rhs in
            isOrdered(lhs, rhs, by: order, uses: uses)
        }
    }
}

private extension EntryList {
    func templateUses(through today: LocalDate) -> [EntryTemplate.ID: Int] {
        let start = today.adding(days: 1 - TemplateOrder.frequentDays)

        var uses: [EntryTemplate.ID: Int] = [:]

        for day in days where day.date >= start && day.date <= today {
            for case let id? in day.entries.map(\.templateId) {
                uses[id, default: 0] += 1
            }
        }

        return uses
    }

    func categoryOrder(of template: EntryTemplate) -> Int {
        categories[template.categoryId]?.sortOrder ?? .max
    }

    func isOrdered(
        _ lhs: EntryTemplate,
        _ rhs: EntryTemplate,
        by order: TemplateOrder,
        uses: [EntryTemplate.ID: Int]
    ) -> Bool {
        switch order {
        case .manual:
            break
        case .frequent:
            let left = uses[lhs.id, default: 0]
            let right = uses[rhs.id, default: 0]

            if left != right {
                return left > right
            }
        case .category:
            let left = categoryOrder(of: lhs)
            let right = categoryOrder(of: rhs)

            if left != right {
                return left < right
            }
        case .amount:
            let left = lhs.amount ?? -1
            let right = rhs.amount ?? -1

            if left != right {
                return left > right
            }
        case .name:
            let result = lhs.name.localizedStandardCompare(rhs.name)

            if result != .orderedSame {
                return result == .orderedAscending
            }
        }

        return lhs.sortOrder < rhs.sortOrder
    }
}
