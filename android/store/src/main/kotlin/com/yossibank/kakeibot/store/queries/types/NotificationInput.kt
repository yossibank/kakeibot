package com.yossibank.kakeibot.store.queries.types

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.notification.NotificationPlan
import com.yossibank.kakeibot.core.concepts.notification.PlannedNotification
import com.yossibank.kakeibot.core.concepts.notification.ReminderTime
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.shared.Identifier

data class NotificationInput(
    val recordedDates: Set<LocalDate>,
    val recurrings: List<Recurring>,
    val reminderTime: ReminderTime?,
    val names: Map<Identifier<EntryCategory>, String>,
    val shortages: List<NotificationPlan.Shortage> = emptyList(),
) {
    fun plan(today: LocalDate): List<PlannedNotification> = NotificationPlan.notifications(
        today = today,
        reminderTime = reminderTime,
        recordedDates = recordedDates,
        recurrings = recurrings,
        names = names,
        shortages = shortages,
    )
}
